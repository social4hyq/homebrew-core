#!/usr/bin/env python3
"""herdr-bridge: lets the Herdr HAP reach the herdr-core on this machine.

A HAP cannot start the host's `hc`, so the app connects here over TCP and this
process owns one `hc connect` per connection, forwarding its stdio both ways.

`hc connect` gives whoever holds the connection the whole core, including
running commands as the person. So this bridge

  * listens on a loopback address only (any other address is refused at start-up);
  * answers only a connection whose first line is `HERDR-AUTH <token>`, where
    the token is the one in the config file `herdr-app install` wrote (and baked
    into the app); anything else is refused before `hc` is started;
  * gives a bad or late first line no hint of what was wrong, and waits a moment
    before refusing it (without holding a connection slot, so a flood of bad
    connections cannot keep the app out).

Config file (`bridge.conf`, mode 0600, two lines):

    addr=127.0.0.1:8765
    token=<hex>

Usage:
    herdr-bridge.py [--config FILE]            run the bridge
    herdr-bridge.py --check [--config FILE]    connect with the token; exit 0 if the bridge accepts it
"""
import argparse
import hmac
import ipaddress
import os
import signal
import socket
import subprocess
import sys
import threading
import time

AUTH_PREFIX = b"HERDR-AUTH "
MAX_AUTH_LINE = 200  # the prefix, a hex token and a newline fit many times over
AUTH_TIMEOUT = 3.0  # seconds a new connection has to send its first line
DENY_DELAY = 0.5  # seconds before a refusal is sent: slows down guessing
MAX_SESSIONS = 16  # authenticated connections at once: the app keeps two
MAX_PENDING = 32  # connections that have not been authenticated yet; a slot is free again as soon as the first line is judged
MIN_TOKEN = 32


def log(message):
    print(time.strftime("%Y-%m-%d %H:%M:%S"), message, flush=True)


def default_config():
    return os.path.join(os.path.expanduser("~"), ".config", "herdr-app", "bridge.conf")


def read_config(path):
    """(host, port, token) from the config file; raises ValueError when it cannot be trusted."""
    values = {}
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, _, value = line.partition("=")
                values[key.strip()] = value.strip()
    addr, token = values.get("addr", ""), values.get("token", "")
    host, sep, port = addr.rpartition(":")
    if not sep or not port.isdigit() or not 0 < int(port) < 65536:
        raise ValueError(f"{path}: addr must be HOST:PORT")
    if not is_loopback(host):
        raise ValueError(f"{path}: addr {addr!r} is not a loopback address; the bridge only listens on 127.0.0.0/8 or ::1")
    if len(token) < MIN_TOKEN:
        raise ValueError(f"{path}: token must be at least {MIN_TOKEN} characters")
    return host.strip("[]"), int(port), token


def is_loopback(host):
    try:
        return ipaddress.ip_address(host.strip("[]")).is_loopback
    except ValueError:
        return False  # a name could resolve to anything


def warn_if_readable(path):
    try:
        mode = os.stat(path).st_mode & 0o077
    except OSError:
        return
    if mode:
        log(f"warning: {path} is readable by others (mode {mode:o} in the group/other bits); on this file system chmod may not take effect")


def pump(read, write, done):
    try:
        while True:
            chunk = read(65536)
            if not chunk:
                break
            write(chunk)
    except (OSError, ValueError):
        pass
    finally:
        done()


def authenticated(conn, rfile, token):
    """True when the connection's first line is `HERDR-AUTH <token>`."""
    conn.settimeout(AUTH_TIMEOUT)
    try:
        line = rfile.readline(MAX_AUTH_LINE + 1)
    except (OSError, ValueError):  # timed out or reset
        return False
    if len(line) > MAX_AUTH_LINE or not line.endswith(b"\n") or not line.startswith(AUTH_PREFIX):
        return False
    given = line[len(AUTH_PREFIX):].rstrip(b"\r\n")
    return hmac.compare_digest(given, token.encode())


def session(conn, rfile, peer, hc):
    """One authenticated connection: `hc connect`, with its stdio forwarded to and from the socket."""
    try:
        proc = subprocess.Popen([hc, "connect"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    except OSError as error:
        log(f"cannot start {hc} connect: {error}")
        conn.sendall(b"ERR\n")
        return
    conn.sendall(b"OK\n")
    conn.settimeout(None)
    log(f"accepted {peer[0]}:{peer[1]}")
    finished = threading.Event()
    up = threading.Thread(target=pump, args=(rfile.read1, lambda b: (proc.stdin.write(b), proc.stdin.flush()), lambda: proc.stdin.close()), daemon=True)
    down = threading.Thread(target=pump, args=(proc.stdout.read1, conn.sendall, finished.set), daemon=True)
    up.start()
    down.start()
    # Either side ending ends the connection: the app going away closes hc's stdin, hc exiting ends the reply stream.
    while not finished.wait(0.2):
        if not up.is_alive():
            finished.wait(3)
            break
    proc.kill()
    proc.wait()
    log(f"closed {peer[0]}:{peer[1]}")


def handle(conn, peer, token, hc, pending, sessions):
    rfile = conn.makefile("rb")
    try:
        ok = authenticated(conn, rfile, token)
        pending.release()  # judged: this connection no longer counts against the unauthenticated limit
        if not ok:
            time.sleep(DENY_DELAY)
            conn.sendall(b"DENIED\n")
            log(f"refused {peer[0]}:{peer[1]}")
        elif not sessions.acquire(blocking=False):
            conn.sendall(b"BUSY\n")  # only a connection that knew the token hears this
            log(f"too many sessions, turned away {peer[0]}:{peer[1]}")
        else:
            try:
                session(conn, rfile, peer, hc)
            finally:
                sessions.release()
    except OSError:
        pass
    finally:
        conn.close()


def serve(config):
    host, port, token = read_config(config)
    warn_if_readable(config)
    hc = os.environ.get("HC_BIN") or os.path.expanduser("~/.harmonybrew/bin/hc")
    family = socket.AF_INET6 if ":" in host else socket.AF_INET
    server = socket.socket(family, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((host, port))
    server.listen(16)
    pending = threading.BoundedSemaphore(MAX_PENDING)
    sessions = threading.BoundedSemaphore(MAX_SESSIONS)
    signal.signal(signal.SIGTERM, lambda *_: server.close())
    log(f"herdr bridge listening on {host}:{port} (hc: {hc})")
    while True:
        try:
            conn, peer = server.accept()
        except OSError:
            log("stopping")
            return 0
        if not is_loopback(peer[0]) or not pending.acquire(blocking=False):
            conn.close()  # no reply: nothing is told to a peer that has not shown the token
            continue
        threading.Thread(target=handle, args=(conn, peer, token, hc, pending, sessions), daemon=True).start()


def check(config):
    host, port, token = read_config(config)
    try:
        with socket.create_connection((host, port), timeout=5) as conn:
            conn.sendall(AUTH_PREFIX + token.encode() + b"\n")
            reply = conn.makefile("rb").readline(32)
    except OSError as error:
        print(f"cannot reach the bridge at {host}:{port}: {error}", file=sys.stderr)
        return 1
    if reply.strip() != b"OK":
        print(f"the bridge at {host}:{port} did not accept the token ({reply.strip().decode(errors='replace') or 'no reply'})", file=sys.stderr)
        return 1
    return 0


def main():
    parser = argparse.ArgumentParser(description="Token-authenticated bridge from the Herdr HAP to herdr-core.")
    parser.add_argument("--config")
    parser.add_argument("--brew-prefix", help="use the home directory that owns the Harmonybrew prefix")
    parser.add_argument("--check", action="store_true", help="connect with the token and report whether the bridge accepts it")
    args = parser.parse_args()
    if args.brew_prefix:
        os.environ["HOME"] = os.path.dirname(os.path.abspath(args.brew_prefix))
    config = args.config or os.environ.get("HERDR_BRIDGE_CONFIG") or default_config()
    try:
        return check(config) if args.check else serve(config)
    except (OSError, ValueError) as error:
        print(f"herdr-bridge: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
