#!/usr/bin/env bash
# opencode-desktop: manage the local opencode serve instance backing the
# OpenCode desktop shell HAP, open the app, and install the HAP.
set -euo pipefail

CONFIG_DIR="${HOME:?HOME must be set}/.config/opencode-desktop"
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
PID_FILE="$CONFIG_DIR/serve.pid"
LOG_FILE="$CONFIG_DIR/serve.log"
DEFAULT_PORT=14199
BUNDLE_ID="com.social4hyq.opencodedesktop"
MODULE="electron"
ABILITY="EntryAbility"

usage() {
  cat <<'EOF'
Usage: opencode-app <command>

Commands:
  start     Open the desktop app (it starts the backend itself when installed
            with the weak-sandbox ACL; needs hdc and an unlocked device)
    --serve-only  Only ensure the backend (for shell startup files)
  serve     Start the backing `opencode serve` instance (background) if needed
  stop      Stop the CLI-managed backing instance
  status    Show whether the backing instance is healthy
  install   Inject config/host env, sign and install the desktop HAP
  -h, --help  Show this help
EOF
}

port_busy() {
  (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null && { exec 3>&- 3<&-; return 0; } || return 1
}

ensure_config() {
  mkdir -p "$CONFIG_DIR"
  # No-op on hmdfs, see the note above CONFIG_FILE; kept for ordinary file systems.
  chmod 700 "$CONFIG_DIR" 2>/dev/null || true
  if [[ ! -f "$CONFIG_FILE" ]]; then
    local port="$DEFAULT_PORT"
    local tries=0
    while port_busy "$port"; do
      port=$((port + 1))
      tries=$((tries + 1))
      if ((tries > 30)); then
        printf 'opencode-desktop: no free loopback port near %s\n' "$DEFAULT_PORT" >&2
        exit 1
      fi
    done
    local password
    password="$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')"
    (umask 077; printf '{"port":%s,"password":"%s"}\n' "$port" "$password" > "$CONFIG_FILE")
    printf 'opencode-desktop: wrote %s (port %s)\n' "$CONFIG_FILE" "$port" >&2
  fi
}

read_config() {
  ensure_config
  PORT="$(sed -n 's/.*"port":\([0-9][0-9]*\).*/\1/p' "$CONFIG_FILE")"
  PASSWORD="$(sed -n 's/.*"password":"\([^"]*\)".*/\1/p' "$CONFIG_FILE")"
  if [[ -z "$PORT" || -z "$PASSWORD" ]]; then
    printf 'opencode-desktop: cannot parse %s\n' "$CONFIG_FILE" >&2
    exit 1
  fi
}

healthy() {
  local auth
  auth="$(printf 'opencode:%s' "$PASSWORD" | base64)"
  [[ "$(curl -s -o /dev/null -w '%{http_code}' -m 3 -H "Authorization: Basic $auth" "http://127.0.0.1:$PORT/api/config" 2>/dev/null)" == "200" ]]
}

# Prints the command line of a live pid, empty if the pid is gone.
# /proc is authoritative on both OHOS and the CI container; ps is only a
# fallback because busybox/procps flavours differ in flag support.
proc_args() {
  local pid="$1"
  if [[ -r "/proc/$pid/cmdline" ]]; then
    tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true
    return 0
  fi
  ps -eo pid,args 2>/dev/null | awk -v pid="$pid" '$1 == pid { $1 = ""; sub(/^ +/, ""); print; exit }'
}

# A pidfile may point at a recycled pid; only treat it as ours when the
# process is alive AND its command line is the serve instance we manage.
is_managed_serve() {
  local pid="$1" args
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  args="$(proc_args "$pid")"
  [[ "$args" == *"opencode serve"* ]]
}

wait_gone() {
  local pid="$1" n=0
  while kill -0 "$pid" 2>/dev/null && ((n < 25)); do
    sleep 0.2
    n=$((n + 1))
  done
}

# Idempotently bring up the managed serve instance.
ensure_serve() {
  read_config
  if healthy; then
    printf 'opencode-desktop: server already healthy at http://127.0.0.1:%s\n' "$PORT"
    return 0
  fi
  if [[ -f "$PID_FILE" ]]; then
    local stale_pid
    stale_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if is_managed_serve "$stale_pid"; then
      printf 'opencode-desktop: stale server process (pid %s) is not responding; stopping it\n' "$stale_pid" >&2
      kill "$stale_pid" 2>/dev/null || true
      wait_gone "$stale_pid"
    fi
    rm -f "$PID_FILE"
  fi
  if port_busy "$PORT"; then
    printf 'opencode-desktop: port %s is in use by another process; edit %s to pick another port\n' "$PORT" "$CONFIG_FILE" >&2
    exit 1
  fi
  OPENCODE_SERVER_PASSWORD="$PASSWORD" nohup opencode serve --hostname 127.0.0.1 --port "$PORT" >>"$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  local waited=0
  until healthy; do
    sleep 1
    waited=$((waited + 1))
    if ((waited > 20)); then
      printf 'opencode-desktop: server did not become healthy; see %s\n' "$LOG_FILE" >&2
      exit 1
    fi
  done
  printf 'opencode-desktop: serving at http://127.0.0.1:%s (log: %s)\n' "$PORT" "$LOG_FILE"
}

# Bring up the app; the shell starts the backend itself on launch (ACL
# install). --serve-only keeps a CLI-managed backend for shell startup files.
cmd_start() {
  local serve_only=0
  while (($#)); do
    case "$1" in
      --serve-only) serve_only=1 ;;
      -h|--help) usage; exit 0 ;;
      *)
        printf 'opencode-desktop: unknown option: %s\n' "$1" >&2
        usage >&2
        exit 2
        ;;
    esac
    shift
  done
  if ((serve_only)); then
    ensure_serve
    return 0
  fi
  if ! command -v hdc >/dev/null 2>&1; then
    printf 'opencode-desktop: hdc not found; install ohos-sdk-toolchains\n' >&2
    exit 1
  fi
  hdc shell aa start -a "$ABILITY" -b "$BUNDLE_ID" -m "$MODULE" >/dev/null
  printf 'opencode-desktop: opened %s\n' "$BUNDLE_ID"
}

cmd_stop() {
  local pid=""
  if [[ -f "$PID_FILE" ]]; then
    pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  fi
  if is_managed_serve "$pid"; then
    kill "$pid" 2>/dev/null || true
    wait_gone "$pid"
    rm -f "$PID_FILE"
    printf 'opencode-desktop: stopped\n'
  else
    rm -f "$PID_FILE"
    printf 'opencode-desktop: no managed server running\n'
  fi
}

cmd_status() {
  read_config
  if healthy; then
    printf 'opencode-desktop: healthy at http://127.0.0.1:%s\n' "$PORT"
  else
    printf 'opencode-desktop: server not healthy at http://127.0.0.1:%s\n' "$PORT" >&2
    exit 1
  fi
}

cmd_install() {
  : "${OPENCODE_DESKTOP_UNSIGNED_HAP:?opencode-desktop formula did not set the unsigned HAP path}"
  : "${OPENCODE_DESKTOP_INSTALL_SCRIPT:?opencode-desktop formula did not set the install script path}"
  # A fresh machine has no config yet; the installer needs port/password and
  # install no longer starts the backend first.
  ensure_config
  exec bash "$OPENCODE_DESKTOP_INSTALL_SCRIPT" \
    --hap "$OPENCODE_DESKTOP_UNSIGNED_HAP" \
    --config "$CONFIG_FILE" "$@"
}

case "${1:-}" in
  start) shift; cmd_start "$@" ;;
  serve) shift; ensure_serve ;;
  stop) shift; cmd_stop "$@" ;;
  status) shift; cmd_status "$@" ;;
  install) shift; cmd_install "$@" ;;
  -h|--help|help) usage ;;
  "") usage >&2; exit 2 ;;
  *) printf 'opencode-desktop: unknown command: %s\n' "$1" >&2; usage >&2; exit 2 ;;
esac
