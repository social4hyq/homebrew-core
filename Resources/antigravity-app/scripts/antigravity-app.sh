#!/usr/bin/env bash
set -euo pipefail

APP_BUNDLE_ID=com.social4hyq.antigravity
APP_MODULE=electron
APP_ABILITY=EntryAbility
APP_INSTALLER=${ANTIGRAVITY_APP_INSTALLER:-app-installer}
HDC=${ANTIGRAVITY_APP_HDC:-${ANTIGRAVITY_APP_HDC_DEFAULT:-hdc}}
INSTALL_SCRIPT=${ANTIGRAVITY_APP_INSTALL_SCRIPT:?missing Antigravity install script path}

usage() {
  cat <<'EOF'
Usage: antigravity-app <command>

  install     Download the official engine, prepare it for OHOS, sign and install.
  start       Start the installed Antigravity app.
  stop        Force-stop the app on the selected device.
  status      Show whether the app is running on the selected device.
  uninstall   Remove the app from the selected device (keeps data unless --purge).

Device options (start/stop/status/uninstall):
  --device ID  hdc target serial (default: HDC_TARGET, else the first device)
  --purge      uninstall only: also delete the app's data
EOF
}

case ${1:-} in
  install)
    shift
    exec "$INSTALL_SCRIPT" "$@"
    ;;
  start|stop|status|uninstall)
    command="$1"; shift
    device="${HDC_TARGET:-}"; purge=0
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --device) [[ $# -ge 2 && -n "$2" ]] || { echo 'antigravity-app: --device needs an id' >&2; exit 2; }; device="$2"; shift 2 ;;
        --purge) [[ "$command" == uninstall ]] || { echo 'antigravity-app: --purge is only for uninstall' >&2; exit 2; }; purge=1; shift ;;
        *) usage >&2; exit 2 ;;
      esac
    done
    command -v "$HDC" >/dev/null
    hdc_args=(); [[ -z "$device" ]] || hdc_args+=(-t "$device")
    case "$command" in
      start) "$HDC" "${hdc_args[@]}" shell aa start -a "$APP_ABILITY" -b "$APP_BUNDLE_ID" -m "$APP_MODULE" ;;
      stop) "$HDC" "${hdc_args[@]}" shell aa force-stop "$APP_BUNDLE_ID"; echo "antigravity-app: stopped $APP_BUNDLE_ID" ;;
      status)
        processes="$("$HDC" "${hdc_args[@]}" shell "ps -ef" 2>/dev/null || true)"
        if printf '%s\n' "$processes" | awk -v bundle="$APP_BUNDLE_ID" '$8 == bundle || index($8, bundle ":") == 1 { found = 1 } END { exit !found }'; then
          echo "antigravity-app: running ($APP_BUNDLE_ID)"
        else
          echo "antigravity-app: not running ($APP_BUNDLE_ID)" >&2
          exit 1
        fi
        ;;
      uninstall)
        args=(uninstall --bundle-id "$APP_BUNDLE_ID")
        [[ -z "$device" ]] || args+=(--device "$device")
        [[ "$purge" == 0 ]] || args+=(--purge)
        "$APP_INSTALLER" "${args[@]}"
        ;;
    esac
    ;;
  -h|--help|help) usage ;;
  *) usage >&2; exit 2 ;;
esac
