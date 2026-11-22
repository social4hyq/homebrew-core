#!/usr/bin/env bash
set -euo pipefail

bundle=com.social4hyq.magpiedesktop
module=electron
ability=EntryAbility

usage() {
  cat <<'EOF'
Usage: magpie-app <command>

Commands:
  install [--no-acl] [--keep] [--device ID]
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

hdc="${MAGPIE_APP_HDC:-${MAGPIE_APP_HDC_DEFAULT:-hdc}}"
app_installer="${MAGPIE_APP_INSTALLER:-app-installer}"
device_args=()
if [[ -n "${HDC_TARGET:-}" ]]; then
  device_args=(-t "$HDC_TARGET")
fi

parse_device() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --device)
        [[ $# -ge 2 && -n "$2" ]] || { printf 'magpie-app: --device needs an id\n' >&2; exit 2; }
        device_args=(-t "$2"); shift 2 ;;
      *) printf 'magpie-app: unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
  done
}

case "${1:-}" in
  start)
    shift
    parse_device "$@"
    "${hdc}" "${device_args[@]}" shell aa start -b "$bundle" -a "$ability" -m "$module"
    ;;
  stop)
    shift
    parse_device "$@"
    "${hdc}" "${device_args[@]}" shell aa force-stop "$bundle"
    printf 'magpie-app: stopped %s\n' "$bundle"
    ;;
  status)
    shift
    parse_device "$@"
    # hdc shell does not reliably pass the remote exit status through, so
    # grep the process list instead of trusting an exit code.
    processes="$("${hdc}" "${device_args[@]}" shell "ps -ef" 2>/dev/null || true)"
    if printf '%s\n' "$processes" | grep -q "$bundle"; then
      printf 'magpie-app: running (%s)\n' "$bundle"
    else
      printf 'magpie-app: not running (%s)\n' "$bundle" >&2
      exit 1
    fi
    ;;
  uninstall)
    shift
    purge=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --purge) purge=1; shift ;;
        --device)
          [[ $# -ge 2 && -n "$2" ]] || { printf 'magpie-app: --device needs an id\n' >&2; exit 2; }
          device_args=(-t "$2"); shift 2 ;;
        *) printf 'magpie-app: unknown option: %s\n' "$1" >&2; exit 2 ;;
      esac
    done
    # app-installer runs 'bm uninstall -k' unless --purge is given, so the
    # app's data survives a plain uninstall.
    args=(uninstall --bundle-id "$bundle")
    [[ ${#device_args[@]} -eq 0 ]] || args+=(--device "${device_args[1]}")
    [[ -z "$purge" ]] || args+=(--purge)
    "$app_installer" "${args[@]}"
    ;;
  install)
    shift
    exec "${MAGPIE_APP_INSTALL_SCRIPT:?formula did not set the install script path}" "$@"
    ;;
  -h|--help|help) usage ;;
  *) usage >&2; exit 2 ;;
esac
