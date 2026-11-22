#!/usr/bin/env bash
# opencode-desktop: manage the opencode background service the OpenCode desktop
# shell HAP connects to, open the app, and install the HAP.
#
# The service is the one `opencode` itself runs for the terminal
# (`opencode service`): the TUI, `opencode run` and the desktop shell all talk
# to the same process, so they see the same sessions. The shell reads the
# address and password from the service's state file; nothing is configured here.
set -euo pipefail

BUNDLE_ID="com.social4hyq.opencodedesktop"
MODULE="electron"
ABILITY="EntryAbility"
# Overridable so tests never touch a real service.
OPENCODE="${OPENCODE_DESKTOP_OPENCODE:-opencode}"

usage() {
  cat <<'EOF'
Usage: opencode-app <command>

Commands:
  start     Open the desktop app (it starts the background service itself when
            installed with the weak-sandbox ACL; needs hdc and an unlocked device)
    --serve-only  Only ensure the background service (for shell startup files)
  serve     Start the opencode background service if it is not running
  stop      Stop the opencode background service (the terminal's `opencode`
            and the desktop app both use it; running sessions end)
  status    Show whether the background service is healthy
  install   Inject host env, sign and install the desktop HAP
  -h, --help  Show this help
EOF
}

# The state file `opencode service` writes: {"url", "password", "pid", ...}.
state_file() {
  printf '%s/opencode/service.json' "${XDG_STATE_HOME:-${HOME:?HOME must be set}/.local/state}"
}

json_field() {
  sed -n "s/.*\"$1\":\"\([^\"]*\)\".*/\1/p" "$(state_file)" 2>/dev/null | head -n 1
}

healthy() {
  local url password
  url="$(json_field url)"
  password="$(json_field password)"
  [[ -n "$url" && -n "$password" ]] || return 1
  [[ "$(curl -s -o /dev/null -w '%{http_code}' -m 3 -u "opencode:$password" "$url/api/config" 2>/dev/null)" == "200" ]]
}

ensure_serve() {
  if ! command -v "$OPENCODE" >/dev/null 2>&1; then
    printf 'opencode-desktop: opencode not found\n' >&2
    exit 1
  fi
  # Idempotent: prints the address when the service is already running.
  "$OPENCODE" service start >/dev/null
  if ! healthy; then
    printf 'opencode-desktop: the background service did not become healthy; run: opencode service status\n' >&2
    exit 1
  fi
  printf 'opencode-desktop: serving at %s\n' "$(json_field url)"
}

# Bring up the app; the shell starts the service itself on launch (ACL
# install). --serve-only keeps a CLI-started service for shell startup files.
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
  # The desktop app never stops the service when it quits, so this is the one
  # place that does.
  "$OPENCODE" service stop >/dev/null
  printf 'opencode-desktop: stopped\n'
}

cmd_status() {
  if healthy; then
    printf 'opencode-desktop: healthy at %s\n' "$(json_field url)"
  else
    printf 'opencode-desktop: background service not healthy; run: opencode-app serve\n' >&2
    exit 1
  fi
}

cmd_install() {
  : "${OPENCODE_DESKTOP_UNSIGNED_HAP:?opencode-desktop formula did not set the unsigned HAP path}"
  : "${OPENCODE_DESKTOP_INSTALL_SCRIPT:?opencode-desktop formula did not set the install script path}"
  exec bash "$OPENCODE_DESKTOP_INSTALL_SCRIPT" \
    --hap "$OPENCODE_DESKTOP_UNSIGNED_HAP" "$@"
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
