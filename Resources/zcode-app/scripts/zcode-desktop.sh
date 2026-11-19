#!/usr/bin/env bash
# zcode-desktop: manage the host `zcode --web` instance that backs the desktop
# shell HAP, install the shell, and bring it to the foreground.
set -euo pipefail

BUNDLE_ID="${ZCODE_DESKTOP_BUNDLE:-com.social4hyq.zcodedesktop}"
# The state (config.json, pid file, log, patched server copies) lives under
# $HOME, not under XDG_CONFIG_HOME: the desktop shell runs `zcode-app serve`
# from its own app sandbox, where the terminal's XDG path (a directory inside
# the terminal app's sandbox) is a different place, so the shell and the CLI
# would end up with two configs, two ports and two pid files.
CONFIG_DIR="${ZCODE_DESKTOP_CONFIG_DIR:-$HOME/.config/zcode-desktop}"
# Older versions kept the state in ${XDG_CONFIG_HOME:-$HOME/.config}/zcode-desktop.
LEGACY_CONFIG_DIR="${XDG_CONFIG_HOME:+$XDG_CONFIG_HOME/zcode-desktop}"
# Permissions of this directory. The device keeps $HOME on its shared hmdfs
# mount, where chmod is a no-op: it returns 0 and changes nothing, so the
# `chmod 700` calls below only take effect on ordinary file systems. Do not try
# to make the directory private by creating it under `umask 077`: that gives
# mode 2700, and on hmdfs nobody can write to a 2700 directory, neither the
# user who created it nor the app's own uid, so install, serve, the pid file and
# the log would all fail with EACCES. Files are different: a file created under
# `umask 077` (mode 600) in the usual 2771 directory is read and written
# normally by the terminal and by the app.
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
Usage: zcode-app <command>

  install [--no-acl] [--keep] [--hap PATH] [--no-serve]
                      Inject the host connection config, sign and install the
                      shell HAP on the connected device; it does not start the
                      backing service (the app starts it, or run `serve`).
                      --hap overrides the bundled unsigned HAP (used by tests
                      and local builds); --keep keeps the signed HAP and prints
                      where; --no-serve is accepted and ignored, for scripts
                      written when install used to start the service.
  serve [--workspace DIR]
                      Start the host `zcode --web` instance (background) if it
                      is not already healthy; with --workspace, switch the
                      workspace and restart the instance.
  start [--no-serve]  Bring the installed app to the foreground; start the
                      backing service first when it is not healthy
                      (--no-serve skips that).
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
  # No-op on hmdfs, see the note above CONFIG_FILE; kept for ordinary file systems.
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
  # No-op on hmdfs, see the note above CONFIG_FILE; kept for ordinary file systems.
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

# True when the process exists. kill -0 also fails (EPERM) for a live process
# that belongs to another user, e.g. the service the desktop shell started,
# which runs as the app's user; that process exists too, so ask /proc.
proc_alive() {
  [ -n "${1:-}" ] || return 1
  kill -0 "$1" 2>/dev/null && return 0
  [ -d "/proc/$1" ]
}

# A live process this user may not signal.
proc_foreign() {
  proc_alive "${1:-}" && ! kill -0 "$1" 2>/dev/null
}

foreign_note() {
  log "the managed server (pid $1) belongs to the desktop app's user, so it cannot be stopped from here"
  log "quit the app from its tray menu, or run: hdc shell aa force-stop $BUNDLE_ID"
}

# Move the state of an older version over once. The old directory is the one the
# CLI (and its running service) used, so its config.json wins over whatever is
# already in the new directory; its pid file only comes along while that
# process is still alive.
migrate_legacy_config() {
  [ -z "${ZCODE_DESKTOP_CONFIG_DIR:-}" ] || return 0
  [ -n "$LEGACY_CONFIG_DIR" ] && [ "$LEGACY_CONFIG_DIR" != "$CONFIG_DIR" ] || return 0
  [ -f "$LEGACY_CONFIG_DIR/config.json" ] || return 0
  mkdir -p "$CONFIG_DIR"
  # No-op on hmdfs, see the note above CONFIG_FILE; kept for ordinary file systems.
  chmod 700 "$CONFIG_DIR" 2>/dev/null || true
  cp "$LEGACY_CONFIG_DIR/config.json" "$CONFIG_DIR/config.json"
  mv "$LEGACY_CONFIG_DIR/config.json" "$LEGACY_CONFIG_DIR/config.json.migrated"
  if [ -f "$LEGACY_CONFIG_DIR/web.pid" ]; then
    local pid
    pid="$(cat "$LEGACY_CONFIG_DIR/web.pid" 2>/dev/null || true)"
    if proc_alive "$pid"; then
      cp "$LEGACY_CONFIG_DIR/web.pid" "$CONFIG_DIR/web.pid"
    fi
    rm -f "$LEGACY_CONFIG_DIR/web.pid"
  fi
  log "moved the service state from $LEGACY_CONFIG_DIR to $CONFIG_DIR"
}

# Returns 1 for a live process of another user (nothing is signalled).
stop_pid() {
  local pid="$1" n=0
  proc_alive "$pid" || return 0
  proc_foreign "$pid" && return 1
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
    if proc_foreign "$stale"; then
      # Another user's process is the service only while it listens on the port;
      # otherwise the pid file is stale and the pid was reused.
      if port_busy "$PORT"; then
        foreign_note "$stale"
        exit 1
      fi
      log "ignoring the pid file: pid $stale belongs to another user and serves nothing on port $PORT"
    elif proc_alive "$stale"; then
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
  local extra=() keep=() hap=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-acl) extra+=("--no-acl"); shift ;;
      --keep) keep+=("--keep"); shift ;;
      --no-serve) shift ;;  # install no longer starts the service; kept so old scripts still run
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
    --config "$CONFIG_FILE" "${extra[@]+"${extra[@]}"}" "${keep[@]+"${keep[@]}"}"
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
      local old
      old="$(cat "$PID_FILE" 2>/dev/null || true)"
      if proc_foreign "$old" && port_busy "$PORT"; then
        foreign_note "$old"
        log "the new workspace is saved and applies the next time the service starts"
        exit 1
      fi
      stop_pid "$old" || true
      rm -f "$PID_FILE"
    fi
  fi
  ensure_serve
}

restart_serve_if_running() {
  local pid=""
  [ -f "$PID_FILE" ] && pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if proc_foreign "$pid"; then
    if port_busy "$PORT"; then
      foreign_note "$pid"
      log "restart the app to pick up the new login"
    else
      rm -f "$PID_FILE"
    fi
    return 0
  fi
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
  local serve=1
  while [ $# -gt 0 ]; do
    case "$1" in
      --no-serve) serve=0; shift ;;
      *) die "unknown start option: $1" ;;
    esac
  done
  if [ "$serve" = 1 ]; then
    read_config
    # A failed start must not keep the window from opening: the shell retries
    # on its own and shows the failure on its waiting page.
    if ! healthy; then
      ( ensure_serve ) || log "warning: the service did not start; the app will wait for it"
    fi
  fi
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
  if proc_foreign "$pid"; then
    read_config
    if port_busy "$PORT"; then
      # Started by the desktop shell: it runs as the app's user and ends with the app.
      foreign_note "$pid"
      exit 1
    fi
    log "ignoring the pid file: pid $pid belongs to another user and serves nothing on port $PORT"
    rm -f "$PID_FILE"
    printf 'zcode-desktop: no managed server running\n'
  elif proc_alive "$pid"; then
    stop_pid "$pid"
    rm -f "$PID_FILE"
    printf 'zcode-desktop: stopped\n'
  else
    rm -f "$PID_FILE"
    printf 'zcode-desktop: no managed server running\n'
  fi
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
  login) shift; cmd_login "$@" ;;
  -h|--help|help) usage ;;
  "") usage >&2; exit 2 ;;
  *) printf 'zcode-desktop: unknown command: %s\n' "$1" >&2; usage >&2; exit 2 ;;
esac
