#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${HOME:?HOME must be set}/.config/deepseek-harness-desktop"
CONFIG_FILE="$CONFIG_DIR/config.json"
PID_FILE="$CONFIG_DIR/web.pid"
LOG_FILE="$CONFIG_DIR/web.log"
URL_FILE="$CONFIG_DIR/web.url"
COOKIE_FILE="$CONFIG_DIR/cookies.txt"
DEFAULT_PORT=14277
BUNDLE_ID="com.social4hyq.deepseekharness"
MODULE="electron"
ABILITY="EntryAbility"

usage() {
  cat <<'EOF'
Usage: deepseek-harness-desktop <command>

Commands:
  start     Open the desktop app (it starts dsh web itself)
    --serve-only  Only ensure the CLI-managed backend
  serve     Start the backing `dsh web` instance in the background if needed
  stop      Stop the CLI-managed backing instance
  status    Verify the backing instance's authenticated Web UI handshake
  install   Inject config/host env, sign and install the desktop HAP
  -h, --help  Show this help
EOF
}

port_busy() {
  (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null && { exec 3>&- 3<&-; return 0; } || return 1
}

ensure_config() {
  mkdir -p "$CONFIG_DIR"
  chmod 700 "$CONFIG_DIR" 2>/dev/null || true
  if [[ ! -f "$CONFIG_FILE" ]]; then
    local port="$DEFAULT_PORT"
    local tries=0
    while port_busy "$port"; do
      port=$((port + 1))
      tries=$((tries + 1))
      if ((tries > 30)); then
        printf 'deepseek-harness-desktop: no free loopback port near %s\n' "$DEFAULT_PORT" >&2
        exit 1
      fi
    done
    (umask 077; printf '{"port":%s}\n' "$port" > "$CONFIG_FILE")
    printf 'deepseek-harness-desktop: wrote %s (port %s)\n' "$CONFIG_FILE" "$port" >&2
  fi
}

read_config() {
  ensure_config
  PORT="$(sed -n 's/.*"port":\([0-9][0-9]*\).*/\1/p' "$CONFIG_FILE")"
  if [[ -z "$PORT" ]]; then
    printf 'deepseek-harness-desktop: cannot parse %s\n' "$CONFIG_FILE" >&2
    exit 1
  fi
}

dsh_bin() {
  if [[ -n "${DSH_DESKTOP_DSH_BIN:-}" ]]; then
    printf '%s' "$DSH_DESKTOP_DSH_BIN"
  else
    command -v dsh
  fi
}

managed_url() {
  [[ -f "$URL_FILE" ]] || return 1
  local url
  url="$(head -1 "$URL_FILE" 2>/dev/null || true)"
  case "$url" in
    "http://127.0.0.1:$PORT/"*"?token="*) printf '%s' "$url" ;;
    *) return 1 ;;
  esac
}

healthy() {
  local url
  url="$(managed_url)" || return 1
  [[ "$(curl -sL -c "$COOKIE_FILE" -b "$COOKIE_FILE" -o /dev/null -w '%{http_code}' -m 5 "$url" 2>/dev/null)" == "200" ]]
}

proc_args() {
  local pid="$1"
  if [[ -r "/proc/$pid/cmdline" ]]; then
    tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true
    return 0
  fi
  ps -eo pid,args 2>/dev/null | awk -v pid="$pid" '$1 == pid { $1 = ""; sub(/^ +/, ""); print; exit }'
}

is_managed_serve() {
  local pid="$1" args
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  args="$(proc_args "$pid")"
  [[ "$args" == *"dsh"* && "$args" == *" web"* ]]
}

wait_gone() {
  local pid="$1" n=0
  while kill -0 "$pid" 2>/dev/null && ((n < 25)); do
    sleep 0.2
    n=$((n + 1))
  done
}

save_printed_url() {
  local url
  url="$(sed -n 's#.*\(http://[^ ]*\).*#\1#p' "$LOG_FILE" | tail -1)"
  case "$url" in
    "http://127.0.0.1:$PORT/"*"?token="*)
      (umask 077; printf '%s\n' "$url" > "$URL_FILE")
      return 0
      ;;
  esac
  return 1
}

ensure_serve() {
  read_config
  if healthy; then
    printf 'deepseek-harness-desktop: server already healthy at http://127.0.0.1:%s\n' "$PORT"
    return 0
  fi
  rm -f "$URL_FILE"
  if [[ -f "$PID_FILE" ]]; then
    local stale_pid
    stale_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    if is_managed_serve "$stale_pid"; then
      printf 'deepseek-harness-desktop: stale server process (pid %s) is not responding; stopping it\n' "$stale_pid" >&2
      kill "$stale_pid" 2>/dev/null || true
      wait_gone "$stale_pid"
    fi
    rm -f "$PID_FILE"
  fi
  if port_busy "$PORT"; then
    printf 'deepseek-harness-desktop: port %s is in use by another process; edit %s to pick another port\n' "$PORT" "$CONFIG_FILE" >&2
    exit 1
  fi
  "$(dsh_bin)" web --host 127.0.0.1 --no-open --port "$PORT" >"$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  local waited=0
  until save_printed_url && healthy; do
    sleep 1
    waited=$((waited + 1))
    if ((waited > 30)); then
      printf 'deepseek-harness-desktop: server did not become healthy; see %s\n' "$LOG_FILE" >&2
      exit 1
    fi
  done
  printf 'deepseek-harness-desktop: serving at http://127.0.0.1:%s (log: %s)\n' "$PORT" "$LOG_FILE"
}

warn_version_mismatch() {
  [[ -n "${DSH_DESKTOP_VERSION:-}" ]] || return 0
  local actual
  actual="$("$(dsh_bin)" --version 2>/dev/null || true)"
  if [[ -n "$actual" && "$actual" != "$DSH_DESKTOP_VERSION" ]]; then
    printf 'deepseek-harness-desktop: warning: desktop %s with CLI %s; matching upstream versions are recommended\n' \
      "$DSH_DESKTOP_VERSION" "$actual" >&2
  fi
}

cmd_start() {
  local serve_only=0
  while (($#)); do
    case "$1" in
      --serve-only) serve_only=1 ;;
      -h|--help) usage; exit 0 ;;
      *) printf 'deepseek-harness-desktop: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
  done
  if ((serve_only)); then
    ensure_serve
    return 0
  fi
  warn_version_mismatch
  local hdc="${DSH_DESKTOP_HDC:-${DSH_DESKTOP_HDC_DEFAULT:-}}"
  if [[ -z "$hdc" ]]; then hdc="$(command -v hdc || true)"; fi
  if [[ -z "$hdc" || ! -x "$hdc" ]]; then
    printf 'deepseek-harness-desktop: hdc not found; install ohos-sdk-toolchains\n' >&2
    exit 1
  fi
  "$hdc" shell aa start -a "$ABILITY" -b "$BUNDLE_ID" -m "$MODULE" >/dev/null
  printf 'deepseek-harness-desktop: opened %s\n' "$BUNDLE_ID"
}

cmd_stop() {
  local pid=""
  if [[ -f "$PID_FILE" ]]; then pid="$(cat "$PID_FILE" 2>/dev/null || true)"; fi
  if is_managed_serve "$pid"; then
    kill "$pid" 2>/dev/null || true
    wait_gone "$pid"
    printf 'deepseek-harness-desktop: stopped\n'
  else
    printf 'deepseek-harness-desktop: no managed server running\n'
  fi
  rm -f "$PID_FILE" "$URL_FILE"
}

cmd_status() {
  read_config
  if healthy; then
    printf 'deepseek-harness-desktop: healthy at http://127.0.0.1:%s\n' "$PORT"
  else
    printf 'deepseek-harness-desktop: server not healthy at http://127.0.0.1:%s\n' "$PORT" >&2
    exit 1
  fi
}

cmd_install() {
  : "${DSH_DESKTOP_UNSIGNED_HAP:?formula did not set the unsigned HAP path}"
  : "${DSH_DESKTOP_INSTALL_SCRIPT:?formula did not set the install script path}"
  ensure_config
  warn_version_mismatch
  exec bash "$DSH_DESKTOP_INSTALL_SCRIPT" --hap "$DSH_DESKTOP_UNSIGNED_HAP" --config "$CONFIG_FILE" "$@"
}

case "${1:-}" in
  start) shift; cmd_start "$@" ;;
  serve) shift; ensure_serve ;;
  stop) shift; cmd_stop "$@" ;;
  status) shift; cmd_status "$@" ;;
  install) shift; cmd_install "$@" ;;
  -h|--help|help) usage ;;
  "") usage >&2; exit 2 ;;
  *) printf 'deepseek-harness-desktop: unknown command: %s\n' "$1" >&2; usage >&2; exit 2 ;;
esac
