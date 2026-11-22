#!/usr/bin/env bash
set -euo pipefail

BUNDLE_ID=com.social4hyq.claudecode
MODULE=electron
ABILITY=EntryAbility

usage() {
  cat <<'EOF'
Usage: claude-code-app <command>

  install [--no-acl] [--device ID] [--deb PATH] [--clean-cache]
          Sign and install the local HAP.
  start [--device ID]
          Open the installed app.
  stop [--device ID]
          Force-stop the app on the device.
  status [--device ID]
          Show whether the app is running on the device.
  uninstall [--device ID] [--purge]
          Remove the app from the device. The default keeps the app's data;
          --purge also deletes it.

Device options: --device ID picks the hdc target (default: HDC_TARGET, else
the first connected device).
EOF
}

hdc_bin="${CLAUDE_CODE_APP_HDC:-${CLAUDE_CODE_APP_HDC_DEFAULT:-hdc}}"
app_installer="${CLAUDE_CODE_APP_INSTALLER:-app-installer}"
device_args=()
if [[ -n "${HDC_TARGET:-}" ]]; then
  device_args=(-t "$HDC_TARGET")
fi

parse_device() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --device)
        [[ $# -ge 2 && -n "$2" ]] || { printf 'claude-code-app: --device needs an id\n' >&2; exit 2; }
        device_args=(-t "$2"); shift 2 ;;
      *) break ;;
    esac
  done
  [[ $# -eq 0 ]] || { usage >&2; exit 2; }
}

case "${1:-}" in
  --help|-h|help)
    usage
    ;;
  install)
    shift
    tmp_parent="${TMPDIR:-/data/storage/el2/base/cache}"
    mkdir -p -- "$tmp_parent"
    work=$(mktemp -d "$tmp_parent/claude-code-app.XXXXXX")
    trap 'rm -rf -- "$work"' EXIT
    "$CLAUDE_CODE_APP_INSTALL_SCRIPT" "$CLAUDE_CODE_APP_UNSIGNED_HAP" "$work" "$@"
    ;;
  start)
    shift
    parse_device "$@"
    exec "$hdc_bin" "${device_args[@]}" shell aa start \
      -a "$ABILITY" -b "$BUNDLE_ID" -m "$MODULE"
    ;;
  stop)
    shift
    parse_device "$@"
    "$hdc_bin" "${device_args[@]}" shell aa force-stop "$BUNDLE_ID"
    printf 'claude-code-app: stopped %s\n' "$BUNDLE_ID"
    ;;
  status)
    shift
    parse_device "$@"
    # hdc shell does not reliably pass the remote exit status through, so
    # grep the process list instead of trusting an exit code.
    processes="$("$hdc_bin" "${device_args[@]}" shell "ps -ef" 2>/dev/null || true)"
    if printf '%s\n' "$processes" | grep -q "$BUNDLE_ID"; then
      printf 'claude-code-app: running (%s)\n' "$BUNDLE_ID"
    else
      printf 'claude-code-app: not running (%s)\n' "$BUNDLE_ID" >&2
      exit 1
    fi
    ;;
  uninstall)
    shift
    purge=0
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --purge) purge=1; shift ;;
        --device)
          [[ $# -ge 2 && -n "$2" ]] || { printf 'claude-code-app: --device needs an id\n' >&2; exit 2; }
          device_args=(-t "$2"); shift 2 ;;
        *) usage >&2; exit 2 ;;
      esac
    done
    # app-installer runs 'bm uninstall -k' unless --purge is given, so the
    # app's data survives a plain uninstall.
    args=(uninstall --bundle-id "$BUNDLE_ID")
    [[ ${#device_args[@]} -eq 0 ]] || args+=(--device "${device_args[1]}")
    [[ $purge -eq 0 ]] || args+=(--purge)
    "$app_installer" "${args[@]}"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
