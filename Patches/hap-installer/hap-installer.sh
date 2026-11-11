#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: hap-installer --hap <unsigned.hap> --bundle-id <id> [options]

Sign an existing HAP with a local DevEco debug profile, install it over hdc,
and start its main ability unless --no-start is given.

Required:
  --hap <path>          Unsigned HAP to install
  --bundle-id <id>      HAP bundle identifier
Options:
  --app-name <name>     Signing project name (default: bundle ID suffix)
  --module <name>       Module to start (default: entry)
  --ability <name>      Ability to start (default: EntryAbility)
  --project-dir <path>  Signing project directory
  --signed-hap <path>   Signed HAP output path
  --device <id>         hdc target serial (default: first connected device)
  --no-start            Install without starting the app
  -h, --help            Show this help
EOF
}

hap=
bundle_id=
app_name=
module=entry
ability=EntryAbility
project_dir=
signed_hap=
device=
start_app=1

while (($#)); do
  case "$1" in
    --hap|--bundle-id|--app-name|--module|--ability|--project-dir|--signed-hap|--device)
      if (($# < 2)) || [[ -z "$2" || "$2" == --* ]]; then
        printf 'hap-installer: missing value for %s\n' "$1" >&2; usage >&2; exit 2
      fi
      key="$1"; value="$2"; shift 2
      case "$key" in
        --hap) hap="$value" ;;
        --bundle-id) bundle_id="$value" ;;
        --app-name) app_name="$value" ;;
        --module) module="$value" ;;
        --ability) ability="$value" ;;
        --project-dir) project_dir="$value" ;;
        --signed-hap) signed_hap="$value" ;;
        --device) device="$value" ;;
      esac
      ;;
    --no-start) start_app=0; ability=; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'hap-installer: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$hap" || -z "$bundle_id" ]]; then usage >&2; exit 2; fi
if [[ ! "$bundle_id" =~ ^[A-Za-z][A-Za-z0-9_.]*$ || ! "$module" =~ ^[A-Za-z][A-Za-z0-9_.-]*$ ]]; then
  printf '%s\n' 'hap-installer: invalid bundle ID or module name' >&2; exit 2
fi
if [[ -n "$ability" && ! "$ability" =~ ^[A-Za-z][A-Za-z0-9_.-]*$ ]]; then
  printf '%s\n' 'hap-installer: invalid ability name' >&2; exit 2
fi
if [[ ! -f "$hap" ]]; then printf 'hap-installer: HAP not found: %s\n' "$hap" >&2; exit 1; fi
for tool in devecocli hdc "$HAP_INSTALLER_SIGNER" "$HAP_SIGN_TOOL"; do
  if ! command -v "$tool" >/dev/null 2>&1 && [[ ! -x "$tool" ]]; then
    printf 'hap-installer: required command not found: %s\n' "$tool" >&2; exit 1
  fi
done

home="${HOME:?HOME must be set}"
app_name="${app_name:-${bundle_id##*.}}"
project_dir="${project_dir:-$home/.hap-installer/projects/$bundle_id}"
signed_hap="${signed_hap:-${TMPDIR:-$home/.cache}/hap-installer/signed/$bundle_id.hap}"
profile="$project_dir/build-profile.json5"

status_output=$(devecocli auth status 2>&1) || {
  printf '%s\n' 'hap-installer: could not check Huawei Developer login status.' >&2; exit 1
}
case "$status_output" in
  *'Not logged in'*|*'未登录'*)
    printf '%s\n' 'A Huawei Developer account login is required; opening DevEco CLI login.'
    devecocli auth login
    status_output=$(devecocli auth status 2>&1) || {
      printf '%s\n' 'hap-installer: could not verify Huawei Developer login.' >&2; exit 1
    }
    case "$status_output" in *'Not logged in'*|*'未登录'*) printf '%s\n' 'hap-installer: login was not completed.' >&2; exit 1 ;; esac
    ;;
esac

if [[ ! -f "$project_dir/AppScope/app.json5" ]]; then
  if [[ -e "$project_dir" ]]; then printf 'hap-installer: incomplete signing project: %s\n' "$project_dir" >&2; exit 1; fi
  mkdir -p "$(dirname "$project_dir")"
  devecocli create --project-path "$project_dir" --app-name "$app_name" --bundle-name "$bundle_id"
fi
if [[ ! -f "$profile" ]]; then printf 'hap-installer: missing signing profile: %s\n' "$profile" >&2; exit 1; fi

printf '%s\n' 'Generating or refreshing the local debug profile for connected devices.'
(cd "$project_dir" && devecocli signature generate --product default)
umask 077
mkdir -p "$(dirname "$signed_hap")"
rm -f "$signed_hap"
"$HAP_INSTALLER_SIGNER" --hap "$hap" --profile "$profile" --output "$signed_hap"

hdc_cmd() {
  if [[ -n "$device" ]]; then hdc -t "$device" "$@"; else hdc "$@"; fi
}
tmp_parent="${TMPDIR:-$home/.cache}"
mkdir -p "$tmp_parent"
parts=$(mktemp -d "$tmp_parent/hap-installer.XXXXXX")
remote="hap-installer-$$"
trap 'rm -rf "$parts"' EXIT
split -b 10000000 "$signed_hap" "$parts/part-"
hdc_cmd shell "rm -f /data/local/tmp/$remote-part-*"
for part in "$parts"/part-*; do hdc_cmd file send "$part" "/data/local/tmp/$remote-$(basename "$part")"; done
hdc_cmd shell "cat /data/local/tmp/$remote-part-* > /data/local/tmp/$remote.hap"
hdc_cmd shell "aa force-stop $bundle_id" || true
if ! install_output=$(hdc_cmd shell "bm install -p /data/local/tmp/$remote.hap" 2>&1); then
  printf '%s\n' "$install_output" >&2; exit 1
fi
printf '%s\n' "$install_output"
if ! printf '%s\n' "$install_output" | grep -qiE 'install bundle successfully|^success'; then
  printf '%s\n' 'hap-installer: device did not report successful installation.' >&2; exit 1
fi
if ((start_app)); then
  start_output=$(hdc_cmd shell "aa start -a $ability -b $bundle_id -m $module" 2>&1) || {
    printf '%s\n' "$start_output" >&2
    printf '%s\n' 'WARN: app start failed (the screen may be locked); start it manually.' >&2
    exit 0
  }
  if printf '%s\n' "$start_output" | grep -qi 'start ability successfully'; then
    printf '%s\n' "$start_output"
  else
    printf '%s\n' "$start_output" >&2
    printf '%s\n' 'WARN: app start was not confirmed; start it manually.' >&2
  fi
fi
