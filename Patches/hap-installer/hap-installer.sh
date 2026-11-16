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
  --profile <path>      Sign with this build-profile.json5 instead of generating
                        a debug profile (e.g. an AGC profile carrying ACLs)
  --hdc <path>          hdc executable (default: packaged hdc)
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
profile_arg=
hdc_bin="${HAP_INSTALLER_HDC:-hdc}"
prepare="${HAP_INSTALLER_PREPARE:-$(dirname "${BASH_SOURCE[0]}")/prepare-profile.cjs}"
start_app=1

while (($#)); do
  case "$1" in
    --hap|--bundle-id|--app-name|--module|--ability|--project-dir|--signed-hap|--device|--profile|--hdc)
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
        --profile) profile_arg="$value" ;;
        --hdc) hdc_bin="$value" ;;
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
for tool in node unzip "$hdc_bin" "$HAP_INSTALLER_SIGNER" "$HAP_SIGN_TOOL"; do
  if ! command -v "$tool" >/dev/null 2>&1 && [[ ! -x "$tool" ]]; then
    printf 'hap-installer: required command not found: %s\n' "$tool" >&2; exit 1
  fi
done

# Validate the actual artifact before any account operation or upload.
node "$prepare" "$hap" "$bundle_id"

connected_targets() {
  "$hdc_bin" list targets -v 2>/dev/null | awk '{for (i=2; i<=NF; i++) if ($i == "Connected") {print $1; break}}'
}
if [[ -z "$device" ]]; then
  targets="$(connected_targets || true)"
  if [[ -z "$targets" ]] && command -v param >/dev/null 2>&1; then
    local_port="$(param get persist.hdc.port 2>/dev/null | tr -d ' \r\n' || true)"
    if [[ "$local_port" =~ ^[0-9]+$ ]] && ((10#$local_port > 0 && 10#$local_port <= 65535)); then
      "$hdc_bin" tconn "127.0.0.1:$local_port" >/dev/null 2>&1 || true
      targets="$(connected_targets || true)"
    fi
  fi
  count=$(printf '%s\n' "$targets" | awk 'NF' | wc -l | tr -d ' ')
  if ((count == 0)); then
    printf '%s\n' 'hap-installer: no connected hdc target; connect and unlock the device, or pass --device.' >&2; exit 1
  elif ((count > 1)); then
    printf 'hap-installer: %s hdc targets attached; pass --device <connect-key>:\n' "$count" >&2
    printf '%s\n' "$targets" | sed 's/^/  /' >&2
    exit 2
  fi
  device="$targets"
fi

home="${HOME:?HOME must be set}"
app_name="${app_name:-${bundle_id##*.}}"
project_dir="${project_dir:-$home/.hap-installer/projects/$bundle_id}"
signed_hap="${signed_hap:-${TMPDIR:-$home/.cache}/hap-installer/signed/$bundle_id.hap}"
profile="${profile_arg:-$project_dir/build-profile.json5}"
if [[ "$hap" -ef "$signed_hap" ]]; then
  printf '%s\n' 'hap-installer: input and output HAP paths must differ.' >&2; exit 2
fi

if [[ -n "$profile_arg" ]]; then
  # A caller-supplied profile (e.g. one carrying ACLs) is used as is: running
  # `signature generate` here would replace it with an auto-signed profile
  # that lacks those permissions.
  if [[ ! -f "$profile" ]]; then printf 'hap-installer: signing profile not found: %s\n' "$profile" >&2; exit 1; fi
  printf '%s\n' "Signing with the given profile: $profile"
else
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

  node "$prepare" "$hap" "$bundle_id" "$project_dir"

  printf '%s\n' 'Generating or refreshing the local debug profile for connected devices.'
  (cd "$project_dir" && devecocli signature generate --product default)
fi
mkdir -p "$(dirname "$signed_hap")"
rm -f "$signed_hap"
# Only the signed output is private: scope 077 to the signer so the chunking
# below (split + hdc file send) runs under the normal umask. A global 077 made
# split fail with "Permission denied" on hmdfs-backed cache directories.
(umask 077; "$HAP_INSTALLER_SIGNER" --hap "$hap" --profile "$profile" --output "$signed_hap")

hdc_cmd() {
  if [[ -n "$device" ]]; then "$hdc_bin" -t "$device" "$@"; else "$hdc_bin" "$@"; fi
}
tmp_parent="${TMPDIR:-$home/.cache}"
mkdir -p "$tmp_parent"
parts=$(mktemp -d "$tmp_parent/hap-installer.XXXXXX")
remote="hap-installer-$$"
cleanup() {
  hdc_cmd shell "rm -f /data/local/tmp/$remote-part-* /data/local/tmp/$remote.hap" >/dev/null 2>&1 || true
  rm -rf "$parts"
}
trap cleanup EXIT
split -b 10000000 "$signed_hap" "$parts/part-"
printf 'Uploading %s to %s\n' "$(basename "$signed_hap")" "$device"
hdc_cmd shell "rm -f /data/local/tmp/$remote-part-*"
remote_parts=()
for part in "$parts"/part-*; do
  name="$remote-$(basename "$part")"
  hdc_cmd file send "$part" "/data/local/tmp/$name"
  remote_parts+=("/data/local/tmp/$name")
done
# Concatenate the parts we just sent by explicit name. A glob that matches
# nothing makes the device's cat read stdin and fail with "cat: -: Broken pipe".
hdc_cmd shell "cat ${remote_parts[*]} > /data/local/tmp/$remote.hap"
hdc_cmd shell "aa force-stop $bundle_id" || true
printf '%s\n' 'Installing the signed HAP on the device.'
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
