#!/usr/bin/env bash
# orca-app: sign and install the Orca desktop shell HAP, and manage the optional
# host-side Orca runtime server (the shell starts its own instance on launch).
set -euo pipefail

BUNDLE_ID="${ORCA_DESKTOP_BUNDLE:-com.social4hyq.orca}"
# Fixed under HOME: every terminal, and the shell's install, must find the same
# state whatever XDG_CONFIG_HOME is (on a device it is the terminal app's own
# sandbox, and a terminal without it would not find the config, the port or the
# pid file). State an older launcher kept under $XDG_CONFIG_HOME/orca-app is
# moved here once, see migrate_legacy_config.
CONFIG_DIR="${ORCA_DESKTOP_CONFIG_DIR:-$HOME/.config/orca-app}"
LEGACY_CONFIG_DIR="${XDG_CONFIG_HOME:+$XDG_CONFIG_HOME/orca-app}"
# Permissions of this directory. The device keeps $HOME on its shared hmdfs
# mount, where chmod is a no-op: it returns 0 and changes nothing, so the
# `chmod 700` calls below only take effect on ordinary file systems. hmdfs also
# ignores the mode a program asks for: a new directory is 2771 (a file 660)
# minus the umask, and it takes its owner from the parent directory. Do not try
# to make this directory private by creating it under `umask 077`. Under a
# directory owned by the synthetic uid 20001006 (HOME, ~/.config, ~/.tmp) that
# gives mode 2700 owned by 20001006, and nobody can write to it: not the user
# who created it and not the app's own uid, so install, serve, the pid file and
# the log would all fail with EACCES. (Under a directory owned by the creating
# user's own uid, such as ~/.cache on this device, a 2700 directory is usable by
# its owner and closed to every other uid.) Files are different: a file created
# under `umask 077` (mode 600) in the usual 2771 directory is read and written
# normally by the terminal and by the app.
CONFIG_FILE="$CONFIG_DIR/config.json"
PID_FILE="$CONFIG_DIR/server.pid"
READY_FILE="$CONFIG_DIR/server.ready.json"
LOG_FILE="$CONFIG_DIR/server.log"
# Which permission variant the shell was installed with (only used to report).
INSTALLED_MODE_FILE="$CONFIG_DIR/installed.mode"
DEFAULT_PORT=6768
ORCA_ROOT="${ORCA_DESKTOP_ROOT:?missing ORCA_DESKTOP_ROOT}"
ORCA_BIN="${ORCA_DESKTOP_ORCA_BIN:-$(command -v orca || true)}"
NODE_BIN="${ORCA_DESKTOP_NODE:-node}"
HDC="${ORCA_DESKTOP_HDC:-${ORCA_DESKTOP_HDC_DEFAULT:-hdc}}"
DATA_ROOT="${ORCA_DESKTOP_DATA:-$HOME/.orca}"
# Where to look for a live pid and how to list processes; tests point these at
# fakes so they never depend on the host's real processes.
PROC_ROOT="${ORCA_DESKTOP_PROC_ROOT:-/proc}"
PS_BIN="${ORCA_DESKTOP_PS:-ps}"

usage() {
  cat <<'EOF'
Usage: orca-app <command>

  install [--port N] [--no-acl] [--keep] [--hap PATH] [--config PATH] [--no-serve]
                      Write the host connection into the shell HAP, sign and
                      install it on the connected device, then open the app
                      (--hap overrides the bundled unsigned HAP, --config reuses
                      a pre-written host config, --no-serve only installs,
                      --no-acl installs the strong-sandbox variant, and --keep
                      keeps the signed HAP and prints where).
  start [--device ID]
                      Open the installed app; it starts the runtime server
                      itself when none is running.
  serve [--port N] [--reclaim]
                      Start a host-side runtime server for browser/CLI use (the
                      app does not need it) and print its browser URL.
                      --reclaim first removes a stale orcad.lock in the data
                      directory, only when the pid it names is gone and no orcad
                      process is running; use it after the runtime was killed or
                      the terminal app was updated (see the failure message).
  status              Show whether the host-side runtime server is healthy.
  stop                Stop the host-side server.
  uninstall [--device ID] [--purge]
                      Uninstall the app from the device. The default keeps the
                      app's data; --purge also deletes it.
  pair                Print the host-side server's browser URL again.
EOF
}

log() { printf 'orca-app: %s\n' "$*" >&2; }
die() { log "$*"; exit 1; }

port_busy() {
  (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null && { exec 3>&- 3<&-; return 0; } || return 1
}

proc_alive() {
  local pid="${1:-}"
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

healthy() {
  "$NODE_BIN" -e '
const http = require("node:http");
const port = Number(process.argv[1]);
const req = http.get({ host: "127.0.0.1", port, path: "/web-index.html", timeout: 1500, agent: false }, (res) => {
  res.resume();
  process.exit(res.statusCode === 200 ? 0 : 1);
});
req.on("timeout", () => { req.destroy(); process.exit(1); });
req.on("error", () => process.exit(1));
' "${PORT:-$DEFAULT_PORT}"
}

read_config() {
  PORT="$DEFAULT_PORT"
  if [ -f "$CONFIG_FILE" ]; then
    local configured
    configured="$("$NODE_BIN" -e 'try{const c=JSON.parse(require("node:fs").readFileSync(process.argv[1],"utf8"));process.stdout.write(Number.isInteger(c.port)&&c.port>0?String(c.port):"")}catch{}' "$CONFIG_FILE" || true)"
    [ -n "$configured" ] && PORT="$configured"
  fi
}

write_config() {
  local port="$1" url="$2"
  mkdir -p "$CONFIG_DIR"
  # The same file carries the install-time spawn settings; keep them.
  "$NODE_BIN" -e '
const fs = require("node:fs");
const [port, url, out] = process.argv.slice(1);
let config = {};
try { config = JSON.parse(fs.readFileSync(out, "utf8")); } catch {}
config.port = Number(port);
config.url = url;
fs.writeFileSync(out, JSON.stringify(config) + "\n");
' "$port" "$url" "$CONFIG_FILE"
}

read_web_client_url() {
  [ -f "$READY_FILE" ] || return 1
  "$NODE_BIN" -e '
const fs = require("node:fs");
const text = fs.readFileSync(process.argv[1], "utf8");
for (const line of text.split("\n")) {
  if (!line.includes("orca_server_ready")) continue;
  try {
    const ready = JSON.parse(line);
    const url = ready && ready.pairing && ready.pairing.webClientUrl;
    if (typeof url === "string" && url.length > 0) {
      process.stdout.write(url);
      process.exit(0);
    }
  } catch {}
}
process.exit(1);
' "$READY_FILE"
}

# Free port near the default: the shell's runtime binds it on this same host.
# Port of the runtime `orca-app serve` left serving: its process is alive, its
# ready record names the port and the port answers. Installing while it runs keeps
# that port, so the shell attaches to it instead of starting a second runtime on
# the next free port.
managed_port() {
  [ -f "$READY_FILE" ] && [ -f "$PID_FILE" ] || return 1
  proc_alive "$(cat "$PID_FILE" 2>/dev/null || true)" || return 1
  local found
  found="$("$NODE_BIN" -e '
const fs = require("node:fs");
for (const line of fs.readFileSync(process.argv[1], "utf8").split("\n")) {
  if (!line.includes("orca_server_ready")) continue;
  try {
    const port = Number(new URL(JSON.parse(line).endpoint).port);
    if (Number.isInteger(port) && port > 0) {
      process.stdout.write(String(port));
      process.exit(0);
    }
  } catch {}
}
process.exit(1);
' "$READY_FILE")" || return 1
  PORT="$found"
  healthy || return 1
  printf '%s' "$found"
}

choose_port() {
  local requested="$1" offset=0 candidate
  while [ "$offset" -lt 50 ]; do
    candidate=$((requested + offset))
    [ "$candidate" -le 65535 ] || break
    port_busy "$candidate" || { printf '%s' "$candidate"; return 0; }
    offset=$((offset + 1))
  done
  die "no free port near $requested"
}

write_install_config() {
  local port="$1"
  mkdir -p "$CONFIG_DIR"
  # No data root: the shell keeps the runtime's state in its own sandbox, where
  # a force-stop can always reclaim the instance lock.
  "$NODE_BIN" - "$port" "$ORCA_BIN" "$CONFIG_FILE" <<'JS'
const fs = require("node:fs");
const [port, orca, out] = process.argv.slice(2);
const env = (name) => (typeof process.env[name] === "string" ? process.env[name] : "");
fs.writeFileSync(out, JSON.stringify({
  port: Number(port),
  orca,
  host: {
    home: env("HOME"),
    path: env("PATH"),
    xdgConfig: env("XDG_CONFIG_HOME"),
    xdgData: env("XDG_DATA_HOME"),
    xdgState: env("XDG_STATE_HOME"),
  },
}, null, 2) + "\n");
JS
}

start_server() {
  local port="$1"
  mkdir -p "$CONFIG_DIR" "$DATA_ROOT"
  rm -f "$READY_FILE"
  : > "$LOG_FILE"
  (
    cd "$HOME"
    ORCA_USER_DATA="$DATA_ROOT" nohup "$NODE_BIN" "$ORCA_ROOT/orcad/orcad-server.js" \
      --port "$port" --bind 127.0.0.1 --web-client-root "$ORCA_ROOT/orcad/web" --json \
      >"$READY_FILE" 2>>"$LOG_FILE" &
    echo $! > "$PID_FILE"
  )
}

# "pid identity" from the data root's orcad.lock, or nothing.
read_lock() {
  [ -f "$DATA_ROOT/orcad.lock" ] || return 1
  "$NODE_BIN" -e '
const fs = require("node:fs");
try {
  const lock = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  if (!Number.isInteger(lock.pid) || lock.pid < 1) process.exit(1);
  process.stdout.write(lock.pid + " " + lock.identity);
} catch {
  process.exit(1);
}
' "$DATA_ROOT/orcad.lock"
}

# "pid command" lines of the running orcad runtimes: node processes that run
# .../orcad/orcad-server.js. Matching the bare words would also catch an editor
# or a shell that only mentions the file name. The process list goes into awk,
# which reads all of it; a `grep -q` there would exit early and, under pipefail,
# make the whole check report "not running" through SIGPIPE.
orcad_processes() {
  local procs
  procs="$("$PS_BIN" -eo pid,args 2>/dev/null || true)"
  printf '%s\n' "$procs" | awk '
    $1 ~ /^[0-9]+$/ && $2 ~ /(^|\/)node$/ && index($0, "orcad/orcad-server.js") {
      sub(/^ +/, "")
      print
    }'
}

# Remove the data root's orcad.lock when its holder is provably gone: the pid it
# names does not exist and no orcad process is running at all. orcad itself
# refuses to take such a lock over on this device, because the home mount may be
# shared with other machines, so this is an explicit, narrow override.
reclaim_lock() {
  local info pid identity
  if ! info="$(read_lock)"; then
    log "no readable lock in $DATA_ROOT; nothing to reclaim"
    return 0
  fi
  pid="${info%% *}"
  identity="${info#* }"
  if [ -e "$PROC_ROOT/$pid" ]; then
    die "the lock in $DATA_ROOT belongs to pid $pid, which is still running; stop it with 'orca-app stop' first"
  fi
  local running
  running="$(orcad_processes)"
  if [ -n "$running" ]; then
    log "an orcad process is running; not removing the lock of pid $pid:"
    printf '%s\n' "$running" | awk 'NR <= 3 { print "orca-app:   " substr($0, 1, 160) }
      END { if (NR > 3) print "orca-app:   ... and " (NR - 3) " more" }' >&2
    die "stop it with 'orca-app stop' (or end that process) and run this again"
  fi
  rm -f "$DATA_ROOT/orcad.lock"
  log "removed the stale lock of pid $pid (identity $identity) from $DATA_ROOT"
}

# Explain a startup failure caused by the data root's lock. Returns 1 for any
# other failure, so the caller falls back to dumping the log.
explain_lock_failure() {
  local info="" pid="?" identity="?"
  if info="$(read_lock)"; then
    pid="${info%% *}"
    identity="${info#* }"
  fi
  if grep -q 'orcad_instance_lock_foreign_identity' "$LOG_FILE" 2>/dev/null; then
    log "the data root $DATA_ROOT is locked by another identity (uid $identity, pid $pid)."
    log "That lock was left by an earlier run, typically after the terminal app was reinstalled or"
    log "updated and its uid changed; orcad never takes such a lock over."
  elif grep -q 'orcad_instance_lock_holder_unverifiable' "$LOG_FILE" 2>/dev/null; then
    log "the data root $DATA_ROOT is locked by an earlier run (pid $pid) that is gone."
    log "orcad cannot prove that here, because the home mount may be shared with other machines."
    log "This happens when the runtime was killed instead of stopped with 'orca-app stop'."
  else
    return 1
  fi
  log "If no Orca runtime is running anywhere that uses this data root, run: orca-app serve --reclaim"
}

ensure_serve() {
  local reclaim="${1:-0}"
  read_config
  if healthy; then
    printf 'orca-app: server already healthy at http://127.0.0.1:%s\n' "$PORT"
    return 0
  fi
  if [ -f "$PID_FILE" ]; then
    local stale
    stale="$(cat "$PID_FILE" 2>/dev/null || true)"
    if proc_alive "$stale"; then
      log "stale server process (pid $stale) is not responding; stopping it"
      stop_pid "$stale"
    fi
    rm -f "$PID_FILE"
  fi
  if port_busy "$PORT"; then
    die "port $PORT is in use by another process; pass --port N or stop the other Orca"
  fi
  [ "$reclaim" = 1 ] && reclaim_lock
  start_server "$PORT"
  local waited=0 url=""
  while :; do
    if url="$(read_web_client_url)"; then
      break
    fi
    if ! proc_alive "$(cat "$PID_FILE" 2>/dev/null || true)"; then
      if explain_lock_failure; then
        die "the local server did not start; see $LOG_FILE"
      fi
      sed -n '1,40p' "$LOG_FILE" >&2 || true
      die "the local server exited during startup; see $LOG_FILE"
    fi
    sleep 1
    waited=$((waited + 1))
    if [ "$waited" -gt 90 ]; then
      die "the local server did not become ready; see $LOG_FILE"
    fi
  done
  write_config "$PORT" "$url"
  printf 'orca-app: serving at http://127.0.0.1:%s (data %s, log %s)\n' "$PORT" "$DATA_ROOT" "$LOG_FILE"
}

stop_pid() {
  local pid="$1" n=0
  proc_alive "$pid" || return 0
  kill "$pid" 2>/dev/null || true
  while proc_alive "$pid" && [ "$n" -lt 25 ]; do
    sleep 0.2
    n=$((n + 1))
  done
  proc_alive "$pid" && kill -9 "$pid" 2>/dev/null || true
}

device() {
  local targets port
  targets="$("$HDC" list targets 2>/dev/null || true)"
  case "$targets" in
    ""|"[Empty]"*|"Empty"*)
      port="$("$HDC" shell param get persist.hdc.port 2>/dev/null | tr -d ' \r\n' || true)"
      if [ -n "$port" ]; then
        "$HDC" tconn "127.0.0.1:$port" >/dev/null 2>&1 || true
      fi
      ;;
  esac
}

cmd_install() {
  # extra is also what decides the installed mode below, so --keep, which does
  # not change the variant, gets its own array.
  local extra=() keep=() hap="" start=1 config="" port=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-acl) extra+=("--no-acl"); shift ;;
      --keep) keep+=("--keep"); shift ;;
      --no-serve) start=0; shift ;;
      --port)
        [ $# -ge 2 ] || die "--port needs a number"
        port="$2"; shift 2 ;;
      --config)
        [ $# -ge 2 ] || die "--config needs a path"
        config="$2"; shift 2 ;;
      --hap)
        [ $# -ge 2 ] || die "--hap needs a path"
        hap="$2"; shift 2 ;;
      *) die "unknown install option: $1" ;;
    esac
  done
  # The tap's automatic install (hap-app in a formula's post_install_steps)
  # exports this so an install never opens the window; a manual install without
  # it keeps the old behaviour of opening the app.
  if [ "${HAP_INSTALLER_NO_START:-0}" != "0" ]; then start=0; fi
  case "${port:-$DEFAULT_PORT}" in
    ""|*[!0-9]*) die "--port needs a number" ;;
  esac
  # The shell starts the runtime itself, so the HAP only needs the port it
  # should bind and the host environment to spawn it in; no single-use pairing
  # link is involved at install time. A runtime that `orca-app serve` left running
  # only contributes its port (managed_port).
  if [ -z "$config" ]; then
    [ -n "$ORCA_BIN" ] && [ -x "$ORCA_BIN" ] || die "orca binary not found; set ORCA_DESKTOP_ORCA_BIN"
    config="$CONFIG_FILE"
    local chosen
    if [ -n "$port" ] || ! chosen="$(managed_port)"; then
      chosen="$(choose_port "${port:-$DEFAULT_PORT}")"
    fi
    write_install_config "$chosen"
  fi
  [ -f "$config" ] || die "host config not found: $config"
  "${ORCA_DESKTOP_INSTALL_SCRIPT:?missing install script}" \
    --hap "${hap:-${ORCA_DESKTOP_UNSIGNED_HAP:?missing unsigned HAP}}" \
    --config "$config" "${extra[@]+"${extra[@]}"}" "${keep[@]+"${keep[@]}"}"
  mkdir -p "$CONFIG_DIR"
  if [ "${#extra[@]}" -gt 0 ]; then
    printf 'no-acl\n' > "$INSTALLED_MODE_FILE"
  else
    printf 'acl\n' > "$INSTALLED_MODE_FILE"
  fi
  [ "$start" = 1 ] || return 0
  device
  cmd_start
}

cmd_serve() {
  local port="" reclaim=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --port)
        [ $# -ge 2 ] || die "--port needs a number"
        port="$2"; shift 2 ;;
      --reclaim) reclaim=1; shift ;;
      *) die "unknown serve option: $1" ;;
    esac
  done
  if [ -n "$port" ]; then
    case "$port" in
      ""|*[!0-9]*) die "--port needs a number" ;;
    esac
    if [ "$port" != "$(read_config >/dev/null; printf '%s' "$PORT")" ]; then
      local pid=""
      [ -f "$PID_FILE" ] && pid="$(cat "$PID_FILE" 2>/dev/null || true)"
      proc_alive "$pid" && stop_pid "$pid"
      rm -f "$PID_FILE" "$CONFIG_FILE"
      DEFAULT_PORT="$port"
    fi
  fi
  ensure_serve "$reclaim"
}

cmd_start() {
  local device_id=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --device)
        [ $# -ge 2 ] || die "--device needs an id"
        device_id="$2"; shift 2 ;;
      *) die "unknown start option: $1" ;;
    esac
  done
  device
  # The shell spawns the runtime server on launch; the host-side serve/status
  # commands are only for using Orca from a browser or the CLI.
  local target=()
  [ -n "$device_id" ] && target=(-t "$device_id")
  "$HDC" "${target[@]}" shell aa start -a EntryAbility -b "$BUNDLE_ID" -m electron >/dev/null
  printf 'orca-app: opened %s\n' "$BUNDLE_ID"
}

# Uninstall through app-installer so the data-handling matches every other
# desktop app: `bm uninstall -k` keeps the app's data unless --purge is given.
cmd_uninstall() {
  local purge="" device_id=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --purge) purge=1; shift ;;
      --device)
        [ $# -ge 2 ] || die "--device needs an id"
        device_id="$2"; shift 2 ;;
      *) die "unknown uninstall option: $1" ;;
    esac
  done
  device_id="${device_id:-${HDC_TARGET:-}}"
  local args=(uninstall --bundle-id "$BUNDLE_ID")
  [ -n "$device_id" ] && args+=(--device "$device_id")
  [ "$purge" = 1 ] && args+=(--purge)
  app-installer "${args[@]}"
}

cmd_status() {
  read_config
  if healthy; then
    local url=""
    url="$(read_web_client_url || true)"
    printf 'orca-app: healthy at http://127.0.0.1:%s\n' "$PORT"
    # A healthy server without a pairing file (the one the shell starts has
    # none) is still healthy: do not let a failed test end the function with 1.
    if [ -n "$url" ]; then
      printf 'orca-app: browser URL %s\n' "$url"
    fi
  else
    printf 'orca-app: server not healthy at http://127.0.0.1:%s\n' "$PORT" >&2
    exit 1
  fi
}

cmd_stop() {
  local pid=""
  [ -f "$PID_FILE" ] && pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if proc_alive "$pid"; then
    stop_pid "$pid"
    rm -f "$PID_FILE"
    printf 'orca-app: stopped\n'
  else
    rm -f "$PID_FILE"
    printf 'orca-app: no managed server running\n'
  fi
}

cmd_pair() {
  read_config
  local url=""
  if url="$(read_web_client_url)"; then
    printf '%s\n' "$url"
    return 0
  fi
  die "no pairing URL yet; start the server with orca-app serve"
}

# Move the state an older launcher kept under $XDG_CONFIG_HOME/orca-app to
# $CONFIG_DIR, once. config.json decides: the old one is renamed afterwards, so
# nothing is repeated. If $CONFIG_DIR already has a config, that one wins and the
# old one is renamed to config.json.superseded, with a single notice. A pid file
# and the pairing file only come along when that server is still running.
migrate_legacy_config() {
  [ -z "${ORCA_DESKTOP_CONFIG_DIR:-}" ] || return 0
  [ -n "$LEGACY_CONFIG_DIR" ] && [ "$LEGACY_CONFIG_DIR" != "$CONFIG_DIR" ] || return 0
  [ -f "$LEGACY_CONFIG_DIR/config.json" ] || return 0
  if [ -f "$CONFIG_FILE" ]; then
    mv "$LEGACY_CONFIG_DIR/config.json" "$LEGACY_CONFIG_DIR/config.json.superseded"
    log "$CONFIG_DIR already has a config; the old one in $LEGACY_CONFIG_DIR is ignored (renamed to config.json.superseded)"
    return 0
  fi
  mkdir -p "$CONFIG_DIR"
  # No-op on hmdfs, see the note above CONFIG_FILE; kept for ordinary file systems.
  chmod 700 "$CONFIG_DIR" 2>/dev/null || true
  cp "$LEGACY_CONFIG_DIR/config.json" "$CONFIG_FILE"
  if [ -f "$LEGACY_CONFIG_DIR/installed.mode" ]; then
    cp "$LEGACY_CONFIG_DIR/installed.mode" "$INSTALLED_MODE_FILE"
  fi
  mv "$LEGACY_CONFIG_DIR/config.json" "$LEGACY_CONFIG_DIR/config.json.migrated"
  if [ -f "$LEGACY_CONFIG_DIR/server.pid" ]; then
    local pid
    pid="$(cat "$LEGACY_CONFIG_DIR/server.pid" 2>/dev/null || true)"
    if proc_alive "$pid"; then
      cp "$LEGACY_CONFIG_DIR/server.pid" "$PID_FILE"
      if [ -f "$LEGACY_CONFIG_DIR/server.ready.json" ]; then
        cp "$LEGACY_CONFIG_DIR/server.ready.json" "$READY_FILE"
      fi
    fi
    rm -f "$LEGACY_CONFIG_DIR/server.pid"
  fi
  log "moved the state from $LEGACY_CONFIG_DIR to $CONFIG_DIR"
}
case "${1:-}" in
  -h|--help|help|"") ;;
  *) migrate_legacy_config ;;
esac

case "${1:-}" in
  install) shift; cmd_install "$@" ;;
  serve) shift; cmd_serve "$@" ;;
  start) shift; cmd_start "$@" ;;
  status) shift; cmd_status "$@" ;;
  stop) shift; cmd_stop "$@" ;;
  uninstall) shift; cmd_uninstall "$@" ;;
  pair) shift; cmd_pair "$@" ;;
  -h|--help|help) usage ;;
  "") usage >&2; exit 2 ;;
  *) printf 'orca-app: unknown command: %s\n' "$1" >&2; usage >&2; exit 2 ;;
esac
