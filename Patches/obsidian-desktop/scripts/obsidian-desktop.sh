#!/usr/bin/env bash
# obsidian-desktop: install/launch the Obsidian shell on HarmonyOS PC.
set -euo pipefail

BUNDLE_ID="${OBSIDIAN_DESKTOP_BUNDLE:-com.social4hyq.obsidiandesktop}"
HDC="${OBSIDIAN_DESKTOP_HDC:-${OBSIDIAN_DESKTOP_HDC_DEFAULT:-hdc}}"

usage() {
  cat <<'EOF'
Usage: obsidian-desktop <command>

  install   Inject the official Obsidian app package into the shell HAP,
            sign it and install it on the connected device.
  start     Bring the app to the foreground.
  status    Show whether the app is running.
  cli ...   Run an Obsidian CLI command against the running app
            (enable Settings -> General -> Command line interface first).
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

case "${1:-}" in
  install)
    shift
    "${OBSIDIAN_DESKTOP_INSTALL_SCRIPT:?missing install script}" "$@"
    ;;
  start)
    device
    "$HDC" shell aa start -a EntryAbility -b "$BUNDLE_ID" -m electron >/dev/null
    echo "opened $BUNDLE_ID"
    ;;
  cli)
    shift
    exec "${OBSIDIAN_DESKTOP_NODE:-node}" \
      "${OBSIDIAN_DESKTOP_CLI:?missing CLI client}" "$@"
    ;;
  status)
    device
    if "$HDC" shell "ps -ef | grep -q $BUNDLE_ID" >/dev/null 2>&1; then
      echo "running"
    else
      echo "stopped"
    fi
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
