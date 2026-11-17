#!/usr/bin/env bash
# orca-app: manage the host Orca runtime server that backs the desktop shell
# HAP, sign and install the shell, and bring it to the foreground.
set -euo pipefail

BUNDLE_ID="${ORCA_DESKTOP_BUNDLE:-com.social4hyq.orca}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/orca-app"
CONFIG_FILE="$CONFIG_DIR/config.json"
PID_FILE="$CONFIG_DIR/server.pid"
READY_FILE="$CONFIG_DIR/server.ready.json"
LOG_FILE="$CONFIG_DIR/server.log"
# Pairing links are single use, so a restart mints a new one; remember which one
# the installed HAP carries to know when it must be refreshed.
INSTALLED_URL_FILE="$CONFIG_DIR/installed.url"
INSTALLED_MODE_FILE="$CONFIG_DIR/installed.mode"
DEFAULT_PORT=6768
ORCA_ROOT="${ORCA_DESKTOP_ROOT:?missing ORCA_DESKTOP_ROOT}"
NODE_BIN="${ORCA_DESKTOP_NODE:-node}"
HDC="${ORCA_DESKTOP_HDC:-${ORCA_DESKTOP_HDC_DEFAULT:-hdc}}"
DATA_ROOT="${ORCA_DESKTOP_DATA:-$HOME/.orca}"

usage() {
  cat <<'EOF'
Usage: orca-app <command>

  install [--no-acl] [--hap PATH] [--config PATH] [--no-serve]
                      Write the host connection into the shell HAP, sign and
                      install it on the connected device, then start the local
                      server (--hap overrides the bundled unsigned HAP; --no-serve
                      skips the start, --no-acl installs the strong-sandbox variant).
  serve [--port N]    Start the local Orca runtime server (background) if it is
                      not already healthy and print its browser URL.
  status              Show whether the local server is healthy.
  stop                Stop the managed local server.
  start               Start the server when needed, refresh the shell's pairing
                      link when the server minted a new one, then bring the app
                      to the foreground.
  pair                Print the browser URL of the running server again.
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
  "$NODE_BIN" -e '
const fs = require("node:fs");
const [port, url, out] = process.argv.slice(1);
fs.writeFileSync(out, JSON.stringify({ port: Number(port), url }) + "\n");
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

config_url() {
  "$NODE_BIN" -e '
const fs = require("node:fs");
try {
  const config = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  if (typeof config.url === "string") process.stdout.write(config.url);
} catch {}
' "$1"
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

ensure_serve() {
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
  start_server "$PORT"
  local waited=0 url=""
  while :; do
    if url="$(read_web_client_url)"; then
      break
    fi
    if ! proc_alive "$(cat "$PID_FILE" 2>/dev/null || true)"; then
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
  local extra=() hap="" serve=1 config=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-acl) extra+=("--no-acl"); shift ;;
      --no-serve) serve=0; shift ;;
      --config)
        [ $# -ge 2 ] || die "--config needs a path"
        config="$2"; shift 2 ;;
      --hap)
        [ $# -ge 2 ] || die "--hap needs a path"
        hap="$2"; shift 2 ;;
      *) die "unknown install option: $1" ;;
    esac
  done
  # --config names an already-written host config (used by tests and by a caller
  # that started the server itself); otherwise start the managed server so the
  # HAP is signed with a live port and pairing code.
  if [ -n "$config" ]; then
    [ -f "$config" ] || die "host config not found: $config"
  else
    ensure_serve
    config="$CONFIG_FILE"
  fi
  "${ORCA_DESKTOP_INSTALL_SCRIPT:?missing install script}" \
    --hap "${hap:-${ORCA_DESKTOP_UNSIGNED_HAP:?missing unsigned HAP}}" \
    --config "$config" "${extra[@]+"${extra[@]}"}"
  mkdir -p "$CONFIG_DIR"
  local installed_url=""
  installed_url="$(config_url "$config")"
  printf '%s\n' "$installed_url" > "$INSTALLED_URL_FILE"
  if [ "${#extra[@]}" -gt 0 ]; then
    printf 'no-acl\n' > "$INSTALLED_MODE_FILE"
  else
    printf 'acl\n' > "$INSTALLED_MODE_FILE"
  fi
  [ "$serve" = 1 ] || return 0
  device
  cmd_start
}

cmd_serve() {
  local port=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --port)
        [ $# -ge 2 ] || die "--port needs a number"
        port="$2"; shift 2 ;;
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
  ensure_serve
}

# The HAP loads a pairing link captured when it was installed, and the runtime
# mints a single-use link per server start; without this every restart (a reboot
# included) would show "Orca refused this browser" in the window.
refresh_install_if_stale() {
  local url="" installed="" mode="" extra=()
  url="$(read_web_client_url)" || die "no pairing URL yet; start the server with orca-app serve"
  [ -f "$INSTALLED_URL_FILE" ] && installed="$(cat "$INSTALLED_URL_FILE" 2>/dev/null || true)"
  if [ -n "$installed" ] && [ "$url" = "$installed" ]; then
    return 0
  fi
  [ -f "$INSTALLED_MODE_FILE" ] && mode="$(cat "$INSTALLED_MODE_FILE" 2>/dev/null || true)"
  [ "$mode" = "no-acl" ] && extra+=(--no-acl)
  log "the server's pairing link changed; re-signing the shell"
  "${ORCA_DESKTOP_INSTALL_SCRIPT:?missing install script}" \
    --hap "${ORCA_DESKTOP_UNSIGNED_HAP:?missing unsigned HAP}" \
    --config "$CONFIG_FILE" "${extra[@]+"${extra[@]}"}"
  mkdir -p "$CONFIG_DIR"
  printf '%s\n' "$url" > "$INSTALLED_URL_FILE"
}

cmd_start() {
  device
  ensure_serve
  refresh_install_if_stale
  "$HDC" shell aa start -a EntryAbility -b "$BUNDLE_ID" -m electron >/dev/null
  printf 'orca-app: opened %s\n' "$BUNDLE_ID"
}

cmd_status() {
  read_config
  if healthy; then
    local url=""
    url="$(read_web_client_url || true)"
    printf 'orca-app: healthy at http://127.0.0.1:%s\n' "$PORT"
    [ -n "$url" ] && printf 'orca-app: browser URL %s\n' "$url"
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

case "${1:-}" in
  install) shift; cmd_install "$@" ;;
  serve) shift; cmd_serve "$@" ;;
  start) shift; cmd_start "$@" ;;
  status) shift; cmd_status "$@" ;;
  stop) shift; cmd_stop "$@" ;;
  pair) shift; cmd_pair "$@" ;;
  -h|--help|help) usage ;;
  "") usage >&2; exit 2 ;;
  *) printf 'orca-app: unknown command: %s\n' "$1" >&2; usage >&2; exit 2 ;;
esac
