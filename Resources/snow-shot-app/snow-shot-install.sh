#!/bin/sh
set -eu

: "${SNOW_SHOT_HAP:?snow-shot-app: SNOW_SHOT_HAP is not configured}"

BUNDLE_ID=com.social4hyq.snowshot
MODULE=entry
ABILITY=QAbility

usage() {
  cat <<'EOF'
Usage: snow-shot-app <command> [options]

  install [--no-start] [--device <id>] [--project-dir <path>] [--signed-hap <path>]
                sign the bottled HAP with a local debug profile, install it on
                a connected device and start it
  start [--device <id>]
                open the installed app
  stop [--device <id>]
                force-stop the app on the device
  status [--device <id>]
                show whether the app is running on the device
  uninstall [--device <id>] [--purge]
                remove the app from the device. The default keeps the app's
                data; --purge also deletes it
  help          show this help

Device options: --device <id> picks the hdc target (default: HDC_TARGET,
else the first connected device).
EOF
}

hdc="${SNOW_SHOT_HDC:-${SNOW_SHOT_HDC_DEFAULT:-hdc}}"

# HarmonyOS PC hdc servers can start without connecting to their own local
# device. Use the bundled hdc and the advertised persist.hdc.port to attach
# it before touching the device.
ensure_device() {
  if ! "$hdc" list targets 2>/dev/null | grep -q '127\.0\.0\.1:'; then
    port="$(param get persist.hdc.port 2>/dev/null | tr -d '[:space:]' || true)"
    if [ -n "$port" ]; then
      "$hdc" tconn "127.0.0.1:$port" >/dev/null 2>&1 || true
    fi
  fi
}

# Parse only --device; the chosen serial lands in $device and $target is
# either empty or "-t <serial>" for hdc calls. Device serials carry no
# spaces, so the intentional word split is safe.
device=""
target=""
parse_device() {
  device="${HDC_TARGET:-}"
  while [ $# -gt 0 ]; do
    case "$1" in
      --device)
        [ $# -ge 2 ] && [ -n "$2" ] || {
          printf '%s\n' 'snow-shot-app: --device needs an id' >&2
          exit 2
        }
        device="$2"
        shift 2
        ;;
      *)
        printf 'snow-shot-app: unknown option: %s\n' "$1" >&2
        exit 2
        ;;
    esac
  done
  if [ -n "$device" ]; then
    target="-t $device"
  else
    target=""
  fi
}

install_hap() {
  for option in "$@"; do
    case "$option" in
      --hap|--hap=*|--bundle-id|--bundle-id=*|--app-name|--app-name=*|--module|--module=*|--ability|--ability=*)
        printf 'snow-shot-app: %s is fixed by this formula\n' "$option" >&2
        exit 2
        ;;
    esac
  done

  ensure_device

  exec app-installer \
    --hap "$SNOW_SHOT_HAP" \
    --bundle-id "$BUNDLE_ID" \
    --app-name SnowShot \
    --module "$MODULE" \
    --ability "$ABILITY" \
    "$@"
}

cmd_start() {
  parse_device "$@"
  ensure_device
  # shellcheck disable=SC2086
  "$hdc" $target shell aa start -a "$ABILITY" -b "$BUNDLE_ID" -m "$MODULE"
}

cmd_stop() {
  parse_device "$@"
  ensure_device
  # shellcheck disable=SC2086
  "$hdc" $target shell aa force-stop "$BUNDLE_ID"
  printf 'snow-shot-app: stopped %s\n' "$BUNDLE_ID"
}

cmd_status() {
  parse_device "$@"
  ensure_device
  # shellcheck disable=SC2086
  processes="$("$hdc" $target shell "ps -ef" 2>/dev/null || true)"
  if printf '%s\n' "$processes" | awk -v bundle="$BUNDLE_ID" '
    $8 == bundle || index($8, bundle ":") == 1 { found = 1 }
    END { exit !found }
  '; then
    printf 'snow-shot-app: running (%s)\n' "$BUNDLE_ID"
  else
    printf 'snow-shot-app: not running (%s)\n' "$BUNDLE_ID" >&2
    exit 1
  fi
}

cmd_uninstall() {
  device="${HDC_TARGET:-}"
  purge=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --purge) purge=1; shift ;;
      --device)
        [ $# -ge 2 ] && [ -n "$2" ] || {
          printf '%s\n' 'snow-shot-app: --device needs an id' >&2
          exit 2
        }
        device="$2"
        shift 2
        ;;
      *)
        printf 'snow-shot-app: unknown option: %s\n' "$1" >&2
        exit 2
        ;;
    esac
  done
  # app-installer runs 'bm uninstall -k' unless --purge is given, so the
  # app's data survives a plain uninstall.
  set -- uninstall --bundle-id "$BUNDLE_ID"
  if [ -n "$device" ]; then
    set -- "$@" --device "$device"
  fi
  [ -z "$purge" ] || set -- "$@" --purge
  app-installer "$@"
}

case "${1:-help}" in
  -h|--help|help)
    usage
    ;;
  install)
    shift
    install_hap "$@"
    ;;
  start)
    shift
    cmd_start "$@"
    ;;
  stop)
    shift
    cmd_stop "$@"
    ;;
  status)
    shift
    cmd_status "$@"
    ;;
  uninstall)
    shift
    cmd_uninstall "$@"
    ;;
  *)
    printf 'snow-shot-app: unknown command: %s\n' "$1" >&2
    usage >&2
    exit 2
    ;;
esac
