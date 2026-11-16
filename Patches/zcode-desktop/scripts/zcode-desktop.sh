#!/usr/bin/env bash
# zcode-desktop: manage the host `zcode --web` instance that backs the desktop
# shell HAP, install the shell, and bring it to the foreground.
set -euo pipefail

BUNDLE_ID="${ZCODE_DESKTOP_BUNDLE:-com.social4hyq.zcodedesktop}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zcode-desktop"
CONFIG_FILE="$CONFIG_DIR/config.json"
PID_FILE="$CONFIG_DIR/web.pid"
LOG_FILE="$CONFIG_DIR/web.log"
DEFAULT_PORT=14299
ZCODE_BIN="${ZCODE_DESKTOP_ZCODE:-zcode}"
HDC="${ZCODE_DESKTOP_HDC:-${ZCODE_DESKTOP_HDC_DEFAULT:-hdc}}"
SECRET_FILE="${ZCODE_DESKTOP_SECRET_FILE:-$HOME/.zcode/v2/credential-secret}"
ZCODE_ROOT="${ZCODE_DESKTOP_ZCODE_ROOT:-}"
BUN_BIN="${ZCODE_DESKTOP_BUN:-}"

usage() {
  cat <<'EOF'
Usage: zcode-desktop <command>

  install [--no-acl] [--hap PATH]
                      Inject the host connection config, sign and install the
                      shell HAP on the connected device, then start the backing
                      service (--hap overrides the bundled unsigned HAP; used by
                      tests and local builds).
  serve [--workspace DIR]
                      Start the host `zcode --web` instance (background) if it
                      is not already healthy; with --workspace, switch the
                      workspace and restart the instance.
  start               Bring the installed app to the foreground.
  status              Show whether the backing service is healthy.
  stop                Stop the CLI-managed backing service.
  login [zai|bigmodel]
                      Sign in through the browser (server-side OAuth, the same
                      flow `zcode login` uses). The account is stored in the
                      shared data root and the managed server is restarted.
EOF
}

log() { printf 'zcode-desktop: %s\n' "$*" >&2; }
die() { log "$*"; exit 1; }

port_busy() {
  (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null && { exec 3>&- 3<&-; return 0; } || return 1
}

ensure_secret() {
  local dir
  dir="$(dirname "$SECRET_FILE")"
  mkdir -p "$dir"
  chmod 700 "$dir" 2>/dev/null || true
  if [ ! -s "$SECRET_FILE" ] || [ "$(wc -c < "$SECRET_FILE")" -lt 32 ]; then
    (umask 077; head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$SECRET_FILE")
    log "generated credential secret at $SECRET_FILE"
  fi
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

ensure_config() {
  mkdir -p "$CONFIG_DIR"
  chmod 700 "$CONFIG_DIR" 2>/dev/null || true
  if [ ! -f "$CONFIG_FILE" ]; then
    local port="$DEFAULT_PORT" tries=0
    while port_busy "$port"; do
      port=$((port + 1))
      tries=$((tries + 1))
      if [ "$tries" -gt 30 ]; then
        die "no free loopback port near $DEFAULT_PORT"
      fi
    done
    printf '{"port":%s,"workspace":"%s"}\n' "$port" "$(json_escape "${1:-$HOME}")" > "$CONFIG_FILE"
    log "wrote $CONFIG_FILE (port $port)"
  fi
}

read_config() {
  ensure_config
  PORT="$(sed -n 's/.*"port"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$CONFIG_FILE" | head -1)"
  WORKSPACE="$(sed -n 's/.*"workspace"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG_FILE" | head -1)"
  [ -n "$PORT" ] || die "cannot parse the port from $CONFIG_FILE"
  [ -n "$WORKSPACE" ] || WORKSPACE="$HOME"
}

healthy() {
  [ "$(curl -s -o /dev/null -w '%{http_code}' -m 3 "http://127.0.0.1:$PORT/api/server-info" 2>/dev/null)" = "200" ]
}

server_version() {
  curl -s -m 3 "http://127.0.0.1:$PORT/api/server-info" 2>/dev/null |
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
}

proc_alive() {
  [ -n "${1:-}" ] && kill -0 "$1" 2>/dev/null
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

resolve_bun() {
  if [ -n "$BUN_BIN" ] && [ -x "$BUN_BIN" ]; then return 0; fi
  BUN_BIN="$(command -v bun || true)"
  [ -n "$BUN_BIN" ] && [ -x "$BUN_BIN" ]
}

# zcode --web advertises itself as a remote source server, so the web client's
# "this computer" project host ("local") is routed to a remote host and project
# creation / sending fails with project.host-offline. Run the bundled server
# directly with projectStorageHostId pinned to "local" instead.
prepare_server() {
  [ -n "$ZCODE_ROOT" ] && [ -f "$ZCODE_ROOT/server/entry-http.js" ] || return 1
  [ -f "$ZCODE_ROOT/agent/zcode.cjs" ] || return 1
  resolve_bun || return 1
  local src="$ZCODE_ROOT/server/entry-http.js" key cache
  key="$(cksum "$src" 2>/dev/null | awk '{print $1"-"$2}')"
  [ -n "$key" ] || return 1
  cache="$CONFIG_DIR/server-$key"
  if [ ! -f "$cache/.zcode-desktop-patched" ]; then
    rm -rf "$cache"
    mkdir -p "$cache"
    cp -R "$ZCODE_ROOT/server/." "$cache/" || return 1
    if ! "$BUN_BIN" -e '
const fs = require("node:fs");
const file = process.argv[1];
let source = fs.readFileSync(file, "utf8");
const pattern = /const projectStorageHostId = remoteHostIdFromWorkspaceIdentity\(\s*buildServerRemoteWorkspaceIdentity\(\{ serverId: options2\.sourceServerId, workspacePath: "\/" \}\)\s*\);/;
if (!pattern.test(source)) process.exit(3);
fs.writeFileSync(file, source.replace(pattern, "const projectStorageHostId = \"local\";"));
' "$cache/entry-http.js"; then
      rm -rf "$cache"
      return 1
    fi
    : > "$cache/.zcode-desktop-patched"
  fi
  SERVER_ENTRY="$cache/entry-http.js"
  return 0
}

start_server() {
  if prepare_server; then
    log "starting the bundled server (local project routing patched)"
    (
      cd "$WORKSPACE" 2>/dev/null || cd "$HOME"
      ZCODE_SERVER_HOST=127.0.0.1 PORT="$PORT" ZCODE_SERVER_WORKSPACE="$WORKSPACE" \
        ZCODE_WEB_STATIC_ROOT="$ZCODE_ROOT/web" ZCODE_SERVER_AUTH_TOKEN="" \
        ZCODE_AGENT_SERVER_ARGS_JSON="[\"$ZCODE_ROOT/agent/zcode.cjs\",\"app-server\",\"--stdio\"]" \
        ZCODE_AGENT_SERVER_COMMAND="$BUN_BIN" \
        ZCODE_CREDENTIAL_SECRET_FILE="$SECRET_FILE" \
        nohup "$BUN_BIN" "$SERVER_ENTRY" >>"$LOG_FILE" 2>&1 &
      echo $! > "$PID_FILE"
    )
  else
    log "warning: could not prepare the patched server; falling back to zcode --web"
    log "warning: project creation will fail with project.host-offline on this build"
    (
      cd "$WORKSPACE" 2>/dev/null || cd "$HOME"
      ZCODE_CREDENTIAL_SECRET_FILE="$SECRET_FILE" nohup "$ZCODE_BIN" --web \
        --workspace "$WORKSPACE" --port "$PORT" --no-open >>"$LOG_FILE" 2>&1 &
      echo $! > "$PID_FILE"
    )
  fi
}

ensure_serve() {
  read_config
  if healthy; then
    printf 'zcode-desktop: server already healthy at http://127.0.0.1:%s\n' "$PORT"
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
    die "port $PORT is in use by another process; remove $CONFIG_FILE and re-run install"
  fi
  ensure_secret
  start_server
  local waited=0
  until healthy; do
    sleep 1
    waited=$((waited + 1))
    if [ "$waited" -gt 40 ]; then
      die "server did not become healthy; see $LOG_FILE"
    fi
  done
  printf 'zcode-desktop: serving at http://127.0.0.1:%s (workspace %s, log %s)\n' "$PORT" "$WORKSPACE" "$LOG_FILE"
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
  local extra=() hap=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-acl) extra+=("--no-acl"); shift ;;
      --hap)
        [ $# -ge 2 ] || die "--hap needs a path"
        hap="$2"; shift 2 ;;
      *) die "unknown install option: $1" ;;
    esac
  done
  ensure_config
  ensure_secret
  "${ZCODE_DESKTOP_INSTALL_SCRIPT:?missing install script}" \
    --hap "${hap:-${ZCODE_DESKTOP_UNSIGNED_HAP:?missing unsigned HAP}}" \
    --config "$CONFIG_FILE" "${extra[@]+"${extra[@]}"}"
  # The shell connects to the host instance; start it right away so the app
  # icon opens the workbench instead of the "waiting for the service" page.
  read_config
  if healthy; then
    printf 'zcode-desktop: service already healthy at http://127.0.0.1:%s\n' "$PORT"
  else
    ensure_serve
  fi
}

cmd_serve() {
  local workspace=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --workspace)
        [ $# -ge 2 ] || die "--workspace needs a path"
        workspace="$2"; shift 2 ;;
      *) die "unknown serve option: $1" ;;
    esac
  done
  if [ -n "$workspace" ]; then
    ensure_config
    read_config
    printf '{"port":%s,"workspace":"%s"}\n' "$PORT" "$(json_escape "$workspace")" > "$CONFIG_FILE"
    log "workspace set to $workspace"
    if [ -f "$PID_FILE" ]; then
      stop_pid "$(cat "$PID_FILE" 2>/dev/null || true)"
      rm -f "$PID_FILE"
    fi
  fi
  ensure_serve
}

restart_serve_if_running() {
  local pid=""
  [ -f "$PID_FILE" ] && pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if proc_alive "$pid"; then
    stop_pid "$pid"
    rm -f "$PID_FILE"
    ensure_serve
  fi
}

cmd_login() {
  local provider="${1:-}"
  case "$provider" in
    ""|zai|bigmodel) ;;
    *) die "unknown provider: $provider (expected zai or bigmodel)" ;;
  esac
  [ -x "$ZCODE_BIN" ] || command -v "$ZCODE_BIN" >/dev/null || die "zcode not found (set ZCODE_DESKTOP_ZCODE)"
  ensure_secret
  log "starting the browser login; if no browser opens, open the URL printed above"
  if ! ZCODE_CREDENTIAL_SECRET_FILE="$SECRET_FILE" "$ZCODE_BIN" login ${provider:+"$provider"}; then
    die "login failed"
  fi
  printf 'zcode-desktop: login completed\n'
  # The account lives in the shared data root; restart a running managed server
  # so the workbench picks it up without a manual bounce.
  read_config
  restart_serve_if_running
}

cmd_start() {
  device
  "$HDC" shell aa start -a EntryAbility -b "$BUNDLE_ID" -m electron >/dev/null
  printf 'zcode-desktop: opened %s\n' "$BUNDLE_ID"
}

cmd_status() {
  read_config
  if healthy; then
    printf 'zcode-desktop: healthy at http://127.0.0.1:%s (zcode %s)\n' "$PORT" "$(server_version)"
  else
    printf 'zcode-desktop: server not healthy at http://127.0.0.1:%s\n' "$PORT" >&2
    exit 1
  fi
}

cmd_stop() {
  local pid=""
  [ -f "$PID_FILE" ] && pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if proc_alive "$pid"; then
    stop_pid "$pid"
    rm -f "$PID_FILE"
    printf 'zcode-desktop: stopped\n'
  else
    rm -f "$PID_FILE"
    printf 'zcode-desktop: no managed server running\n'
  fi
}

case "${1:-}" in
  install) shift; cmd_install "$@" ;;
  serve) shift; cmd_serve "$@" ;;
  start) shift; cmd_start "$@" ;;
  status) shift; cmd_status "$@" ;;
  stop) shift; cmd_stop "$@" ;;
  login) shift; cmd_login "$@" ;;
  -h|--help|help) usage ;;
  "") usage >&2; exit 2 ;;
  *) printf 'zcode-desktop: unknown command: %s\n' "$1" >&2; usage >&2; exit 2 ;;
esac
