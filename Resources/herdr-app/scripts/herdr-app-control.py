#!/usr/bin/env python3
"""Drive the Herdr window on the device through herdr-core documents.

The app's control UNIX socket lives inside the HAP sandbox and cannot be
reached from the host. Instead, both sides meet in the core's document store:

  * this client writes a request to the `herdr-app.control` document;
  * the app polls that document, authenticates the request against the bridge
    token baked into the HAP, runs the command through its own control()
    dispatcher, and writes the answer to `herdr-app.control.reply`;
  * this client polls the reply document for its request id.

This is the host half. The `herdr-app do/ls/commands/status` subcommands of
herdr-app.sh call it. Protocol errors and timeouts are reported on stderr and
a non-zero exit, like the upstream control.rs client.
"""
import argparse
import json
import os
import random
import subprocess
import sys
import time

REQ_DOC = "herdr-app.control"
REPLY_DOC = "herdr-app.control.reply"
DEFAULT_TIMEOUT = 5.0
SHOT_TIMEOUT = 35.0
POLL_INTERVAL = 0.05


def fail(message):
    print(f"herdr-app: {message}", file=sys.stderr)
    sys.exit(1)


def rpc(hc, method, params):
    """One JSON-RPC call over a fresh `hc connect` with framed:false (line protocol).

    Returns the result, or a dict with an `error` key for a JSON-RPC error, or
    None when no answer came. Callers decide what an error means (CAS writes
    treat a `conflict` as a retry, everything else is fatal).
    """
    line = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
    try:
        proc = subprocess.run(
            [hc, "connect"], input=(line + "\n").encode(),
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=10,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        fail(f"cannot talk to herdr-core: {error}")
    for raw in proc.stdout.splitlines():
        try:
            msg = json.loads(raw)
        except ValueError:
            continue
        if msg.get("id") == 1:
            if "error" in msg:
                return {"error": msg["error"]}
            return msg.get("result")
    return None


def doc_get(hc, name):
    result = rpc(hc, "doc.get", {"name": name}) or {}
    if isinstance(result, dict) and "error" in result:
        fail(f"herdr-core: {result['error'].get('message', result['error'])}")
    return result.get("value"), result.get("version", 0)


def doc_set(hc, name, version, value):
    """CAS write. True on success, False on a version conflict (caller retries)."""
    result = rpc(hc, "doc.set", {"name": name, "version": version, "value": value})
    if isinstance(result, dict) and "error" in result:
        kind = result["error"].get("data", {}).get("kind") if isinstance(result["error"], dict) else None
        if kind == "conflict":
            return False
        fail(f"herdr-core: {result['error'].get('message', result['error'])}")
    return True


def build_command(argv):
    """Mirror control.rs::client's arg shapes: do/ls/status/commands/shot/feedback."""
    if not argv:
        fail("usage: herdr-app do|ls|status|commands|shot|feedback ...")
    verb, *rest = argv
    if verb == "commands" and not rest:
        # commands is served locally by the upstream control.rs listing; the app
        # answer is identical, so keep it on the same path as the rest.
        return {"commands": True}
    if verb == "status" and not rest:
        return {"status": True}
    if verb == "ls" and not rest:
        return {"ls": True}
    if verb == "shot" and len(rest) <= 1:
        path = os.path.abspath(rest[0] if rest else "herdr-shot.png")
        if not path.lower().endswith(".png"):
            fail("screenshot path must end in .png")
        return {"shot": path}
    if verb == "feedback" and len(rest) == 1:
        return {"do": "app.feedback", "args": {"message": rest[0], "from": "agent"}}
    if verb == "do" and rest:
        return {"do": rest[0], "args": parse_args(rest[1:])}
    fail("usage: herdr-app do <command> [--arg value ... | json] | ls | status | commands | shot [file.png]")


def parse_args(rest):
    """`--name value --argv '[...]'` or one JSON object; values that parse as JSON are JSON."""
    if not rest:
        return {}
    if len(rest) == 1 and rest[0].lstrip().startswith(("{", "[")):
        try:
            value = json.loads(rest[0])
        except ValueError as error:
            fail(f"bad JSON arguments: {error}")
        if not isinstance(value, dict):
            fail("JSON arguments must be an object")
        return value
    args = {}
    i = 0
    while i < len(rest):
        item = rest[i]
        if not item.startswith("--") or item == "--":
            fail(f"expected --name, got {item!r}")
        key = item[2:]
        if not key:
            fail("empty argument name")
        if i + 1 >= len(rest):
            fail(f"missing value for --{key}")
        raw = rest[i + 1]
        try:
            args[key] = json.loads(raw)
        except ValueError:
            args[key] = raw
        i += 2
    return args


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--hc", default=os.environ.get("HERDR_APP_HC", "hc"))
    parser.add_argument("--token", default=os.environ.get("HERDR_APP_BRIDGE_TOKEN"))
    parser.add_argument("--timeout", type=float, default=None)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    opts = parser.parse_args()
    hc = opts.hc
    token = opts.token
    if not token:
        conf = os.path.join(os.environ.get("HERDR_APP_STATE", os.path.expanduser("~/.config/herdr-app")), "bridge.conf")
        try:
            with open(conf, encoding="utf-8") as handle:
                for line in handle:
                    if line.strip().startswith("token="):
                        token = line.strip().split("=", 1)[1]
        except OSError:
            pass
    if not token:
        fail("no bridge token; run `herdr-app install` or set HERDR_APP_BRIDGE_TOKEN")
    cmd = build_command(opts.command)
    timeout = opts.timeout or (SHOT_TIMEOUT if "shot" in cmd else DEFAULT_TIMEOUT)
    rid = f"{int(time.time() * 1000)}-{random.randrange(1 << 30):x}"

    # CAS write of the request document (retry if another client won the race).
    for attempt in range(8):
        _, version = doc_get(hc, REQ_DOC)
        if doc_set(hc, REQ_DOC, version, {"id": rid, "token": token, "cmd": cmd}):
            break
    else:
        fail("could not write the request (too many concurrent clients)")

    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        reply, _ = doc_get(hc, REPLY_DOC)
        if isinstance(reply, dict) and reply.get("id") == rid:
            answer = reply.get("reply", {"error": reply.get("error", "no reply from the app")})
            print(json.dumps(answer, indent=2, ensure_ascii=False))
            if "shot" in cmd and isinstance(answer, dict) and answer.get("path"):
                print(answer["path"])
            sys.exit(1 if isinstance(answer, dict) and "error" in answer else 0)
        time.sleep(POLL_INTERVAL)
    fail("the window did not answer in time")


if __name__ == "__main__":
    main()
