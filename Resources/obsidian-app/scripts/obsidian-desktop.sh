#!/usr/bin/env bash
# obsidian-desktop: install/launch the Obsidian shell on HarmonyOS PC.
set -euo pipefail

BUNDLE_ID="${OBSIDIAN_DESKTOP_BUNDLE:-com.social4hyq.obsidiandesktop}"
HDC="${OBSIDIAN_DESKTOP_HDC:-${OBSIDIAN_DESKTOP_HDC_DEFAULT:-hdc}}"
APP_INSTALLER="${OBSIDIAN_DESKTOP_INSTALLER:-app-installer}"

usage() {
  cat <<'EOF'
Usage: obsidian-app <command>

  install   Inject the official Obsidian app package into the shell HAP,
            sign it and install it on the connected device.
  start [--device ID]
            Bring the app to the foreground.
  stop [--device ID]
            Force-stop the app on the device.
  status [--device ID]
            Show whether the app is running.
  uninstall [--device ID] [--purge]
            Remove the app from the device. The default keeps the app's
            data; --purge also deletes it.
  cli ...   Run an Obsidian CLI command against the running app
            (enable Settings -> General -> Command line interface first).
  smoke     Run a real-device smoke test of the CLI bridge (read-only).

Device options: --device ID picks the hdc target (default: HDC_TARGET, else
the first connected device).
EOF
}

device() {
  local targets
  targets="$("$HDC" list targets 2>/dev/null || true)"
  if [ -z "$targets" ] || [ "$targets" = "[Empty]" ]; then
    local port
    port="$("$HDC" shell param get persist.hdc.port 2>/dev/null | tr -d '\r' || true)"
    if [ -n "$port" ]; then
      "$HDC" tconn "127.0.0.1:$port" >/dev/null 2>&1 || true
    fi
  fi
}

device_args=()
if [ -n "${HDC_TARGET:-}" ]; then
  device_args=(-t "$HDC_TARGET")
fi

parse_device() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --device)
        [ $# -ge 2 ] && [ -n "$2" ] || { printf 'obsidian-app: --device needs an id\n' >&2; exit 2; }
        device_args=(-t "$2"); shift 2 ;;
      *) printf 'obsidian-app: unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
  done
}

case "${1:-}" in
  install)
    shift
    "${OBSIDIAN_DESKTOP_INSTALL_SCRIPT:?missing install script}" "$@"
    ;;
  start)
    shift
    parse_device "$@"
    device
    "${HDC}" "${device_args[@]}" shell aa start -a EntryAbility -b "$BUNDLE_ID" -m electron >/dev/null
    echo "opened $BUNDLE_ID"
    ;;
  stop)
    shift
    parse_device "$@"
    device
    "${HDC}" "${device_args[@]}" shell aa force-stop "$BUNDLE_ID"
    echo "stopped $BUNDLE_ID"
    ;;
  cli)
    shift
    exec "${OBSIDIAN_DESKTOP_NODE:-node}" \
      "${OBSIDIAN_DESKTOP_CLI:?missing CLI client}" "$@"
    ;;
  smoke)
    shift
    exec "${OBSIDIAN_DESKTOP_SMOKE:?missing smoke script}" "$@"
    ;;
  status)
    shift
    parse_device "$@"
    device
    processes="$("${HDC}" "${device_args[@]}" shell "ps -ef" 2>/dev/null || true)"
    if printf '%s\n' "$processes" | awk -v bundle="$BUNDLE_ID" '
      $8 == bundle || index($8, bundle ":") == 1 { found = 1 }
      END { exit !found }
    '; then
      echo "running"
    else
      echo "stopped"
    fi
    ;;
  uninstall)
    shift
    purge=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --purge) purge=1; shift ;;
        --device)
          [ $# -ge 2 ] && [ -n "$2" ] || { printf 'obsidian-app: --device needs an id\n' >&2; exit 2; }
          device_args=(-t "$2"); shift 2 ;;
        *) printf 'obsidian-app: unknown option: %s\n' "$1" >&2; exit 2 ;;
      esac
    done
    # app-installer runs 'bm uninstall -k' unless --purge is given, so the
    # app's data survives a plain uninstall.
    args=(uninstall --bundle-id "$BUNDLE_ID")
    [ ${#device_args[@]} -eq 0 ] || args+=(--device "${device_args[1]}")
    [ -z "$purge" ] || args+=(--purge)
    "$APP_INSTALLER" "${args[@]}"
    ;;
  -h|--help|"")
    usage
    ;;
  *)
    echo "unknown command: $1" >&2
    usage >&2
    exit 1
    ;;
esac
