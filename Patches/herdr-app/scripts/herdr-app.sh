#!/usr/bin/env bash
# herdr-app: sign and install the Herdr desktop HAP, and open it.
set -euo pipefail

BUNDLE_ID="com.social4hyq.herdrapp"
ABILITY="EntryAbility"

usage() {
  cat <<'EOF'
Usage: herdr-app <command> [--device <hdc serial>]

Commands:
  install   Sign the HAP with a local debug profile, install it over hdc and
            open it (needs hdc and an unlocked device)
  start     Open the installed app
  -h, --help  Show this help
EOF
}

die() {
  printf 'herdr-app: %s\n' "$1" >&2
  exit "${2:-1}"
}

command_name="${1:-}"
case "$command_name" in
  -h|--help|help|"") usage; [[ -n "$command_name" ]] || exit 2; exit 0 ;;
  install|start) shift ;;
  *) usage >&2; exit 2 ;;
esac

device=
while (($#)); do
  case "$1" in
    --device)
      (($# >= 2)) && [[ -n "$2" && "$2" != --* ]] || die "missing value for --device" 2
      device="$2"
      shift 2 ;;
    *) usage >&2; exit 2 ;;
  esac
done

hdc="${HERDR_APP_HDC:-${HERDR_APP_HDC_DEFAULT:-hdc}}"
hdc_args=()
[[ -z "$device" ]] || hdc_args=(-t "$device")

case "$command_name" in
  install)
    hap="${HERDR_APP_HAP:?formula did not set the HAP path}"
    [[ -f "$hap" ]] || die "HAP not found: $hap"
    command -v app-installer >/dev/null || die "command not found: app-installer"
    install_args=(--hap "$hap" --bundle-id "$BUNDLE_ID" --app-name Herdr --module entry --ability "$ABILITY" --hdc "$hdc")
    [[ -z "$device" ]] || install_args+=(--device "$device")
    app-installer "${install_args[@]}"
    ;;
  start)
    "$hdc" ${hdc_args[@]+"${hdc_args[@]}"} shell aa start -b "$BUNDLE_ID" -a "$ABILITY"
    ;;
esac
