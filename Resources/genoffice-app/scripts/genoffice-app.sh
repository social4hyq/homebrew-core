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
  install [--no-acl] [--keep] [--hap PATH] [--device ID]
            Sign and install the desktop HAP (needs hdc and an unlocked device)
  start [--device ID]
            Open the app on the device
  stop [--device ID]
            Force-stop the app on the device
  status [--device ID]
            Show whether the app is running on the device
  uninstall [--device ID] [--purge]
            Remove the app from the device. The default keeps the app's data;
            --purge also deletes it.
  -h, --help  Show this help

Device options: --device ID picks the hdc target (default: HDC_TARGET, else
the first connected device).
EOF
}

HDC="${GENOFFICE_DESKTOP_HDC:-${GENOFFICE_DESKTOP_HDC_DEFAULT:-hdc}}"
APP_INSTALLER="${GENOFFICE_DESKTOP_INSTALLER:-app-installer}"
device_args=()
if [[ -n "${HDC_TARGET:-}" ]]; then
  device_args=(-t "$HDC_TARGET")
fi

parse_device() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --device)
        [[ $# -ge 2 && -n "$2" ]] || { printf 'genoffice-app: --device needs an id\n' >&2; exit 2; }
        device_args=(-t "$2"); shift 2 ;;
      *) printf 'genoffice-app: unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
  done
}

cmd_start() {
  parse_device "$@"
  if ! command -v "$HDC" >/dev/null 2>&1 && [[ ! -x "$HDC" ]]; then
    printf 'genoffice-app: hdc not found; install ohos-sdk-toolchains\n' >&2
    exit 1
  fi
  "${HDC}" "${device_args[@]}" shell aa start -a "$ABILITY" -b "$BUNDLE_ID" -m "$MODULE" >/dev/null
  printf 'genoffice-app: opened %s\n' "$BUNDLE_ID"
}

cmd_stop() {
  parse_device "$@"
  "${HDC}" "${device_args[@]}" shell aa force-stop "$BUNDLE_ID"
  printf 'genoffice-app: stopped %s\n' "$BUNDLE_ID"
}

cmd_status() {
  parse_device "$@"
  # Match only app command names; unrelated shell arguments may mention the bundle.
  processes="$("${HDC}" "${device_args[@]}" shell "ps -ef" 2>/dev/null || true)"
  if printf '%s\n' "$processes" | awk -v bundle="$BUNDLE_ID" '
    $8 == bundle || index($8, bundle ":") == 1 { found = 1 }
    END { exit !found }
  '; then
    printf 'genoffice-app: running (%s)\n' "$BUNDLE_ID"
  else
    printf 'genoffice-app: not running (%s)\n' "$BUNDLE_ID" >&2
    exit 1
  fi
}

cmd_uninstall() {
  local purge=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --purge) purge=1; shift ;;
      --device)
        [[ $# -ge 2 && -n "$2" ]] || { printf 'genoffice-app: --device needs an id\n' >&2; exit 2; }
        device_args=(-t "$2"); shift 2 ;;
      *) printf 'genoffice-app: unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  # app-installer runs 'bm uninstall -k' unless --purge is given, so the
  # app's data survives a plain uninstall.
  local args=(uninstall --bundle-id "$BUNDLE_ID")
  [[ ${#device_args[@]} -eq 0 ]] || args+=(--device "${device_args[1]}")
  [[ -z "$purge" ]] || args+=(--purge)
  "$APP_INSTALLER" "${args[@]}"
}

cmd_install() {
  : "${GENOFFICE_DESKTOP_INSTALL_SCRIPT:?genoffice-app formula did not set the install script path}"
  exec bash "$GENOFFICE_DESKTOP_INSTALL_SCRIPT" "$@"
}

case "${1:-}" in
  start) shift; cmd_start "$@" ;;
  install) shift; cmd_install "$@" ;;
  stop) shift; cmd_stop "$@" ;;
  status) shift; cmd_status "$@" ;;
  uninstall) shift; cmd_uninstall "$@" ;;
  -h | --help | help) usage ;;
  *) usage >&2; exit 2 ;;
esac
