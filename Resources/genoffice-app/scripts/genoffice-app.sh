#!/usr/bin/env bash
# genoffice-app: install and start the GenOffice desktop HAP.
set -euo pipefail

BUNDLE_ID="com.social4hyq.genoffice"
MODULE="electron"
ABILITY="EntryAbility"

usage() {
  cat <<'EOF'
Usage: genoffice-app <command>

Commands:
  install   Sign and install the desktop HAP (needs hdc and an unlocked device)
  start     Open the app on the device
  -h, --help  Show this help
EOF
}

cmd_start() {
  local hdc="${GENOFFICE_DESKTOP_HDC:-${GENOFFICE_DESKTOP_HDC_DEFAULT:-hdc}}"
  if ! command -v "$hdc" >/dev/null 2>&1; then
    printf 'genoffice-app: hdc not found; install ohos-sdk-toolchains\n' >&2
    exit 1
  fi
  "$hdc" shell aa start -a "$ABILITY" -b "$BUNDLE_ID" -m "$MODULE" >/dev/null
}

cmd_install() {
  : "${GENOFFICE_DESKTOP_INSTALL_SCRIPT:?genoffice-app formula did not set the install script path}"
  exec bash "$GENOFFICE_DESKTOP_INSTALL_SCRIPT" "$@"
}

case "${1:-}" in
  start) shift; cmd_start "$@" ;;
  install) shift; cmd_install "$@" ;;
  -h | --help | help) usage ;;
  *) usage >&2; exit 2 ;;
esac
