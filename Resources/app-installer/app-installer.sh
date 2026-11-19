#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: app-installer --hap <unsigned.hap> --bundle-id <id> [options]
       app-installer install   --hap <unsigned.hap> --bundle-id <id> [options]
       app-installer uninstall --bundle-id <id> [--device <id>] [--hdc <path>]
       app-installer info      --bundle-id <id> [--device <id>] [--hdc <path>]
       app-installer doctor    [--device <id>] [--hdc <path>]

Sign an existing HAP with a local DevEco debug profile, install it over hdc,
and start its main ability unless --no-start is given. `install` is the default
command.

Required (install):
  --hap <path>          Unsigned HAP to install
  --bundle-id <id>      HAP bundle identifier
Options:
  --app-name <name>     Signing project name (default: bundle ID suffix)
  --module <name>       Module to start (default: entry)
  --ability <name>      Ability to start (default: EntryAbility)
  --project-dir <path>  Signing project directory
  --signed-hap <path>   Signed HAP output path (alias: --output)
  --profile <path>      Sign with this build-profile.json5 instead of generating
                        a debug profile (e.g. an AGC profile carrying ACLs)
  --sign-only           Sign and write the HAP, then stop: no device, no hdc
  --method <m>          auto (default), hdc or sideload. auto uses the system
                        sideload entry once the system offers one, hdc until then
  --hdc <path>          hdc executable (default: packaged hdc)
  --device <id>         hdc target serial (default: first connected device)
  --no-start            Install without starting the app
  --no-browser          Do not open the Huawei Developer login page automatically
  -h, --help            Show this help

Your own signing material (skips the Huawei Developer login; all five needed
together, passwords are read from the environment, never from the command line):
  --keystore <p12>        --cert <cer|pem>        --profile-file <p7b>
  --key-alias <alias>     --sign-alg <alg>        (default SHA256withECDSA)
  APP_INSTALLER_KEYSTORE_PWD  keystore password
  APP_INSTALLER_KEY_PWD       key password (default: the keystore password)
EOF
}

die() { printf 'app-installer: %s\n' "$1" >&2; exit "${2:-1}"; }

cmd=install
case "${1:-}" in
  install|uninstall|info|doctor) cmd="$1"; shift ;;
esac

hap=
bundle_id=
app_name=
module=entry
ability=EntryAbility
project_dir=
signed_hap=
device=
profile_arg=
method=auto
sign_only=0
keystore=
cert=
profile_file=
key_alias=
sign_alg=
hdc_bin="${HAP_INSTALLER_HDC:-hdc}"
prepare="${HAP_INSTALLER_PREPARE:-$(dirname "${BASH_SOURCE[0]}")/prepare-profile.cjs}"
start_app=1
open_browser=1

while (($#)); do
  case "$1" in
    --hap|--bundle-id|--app-name|--module|--ability|--project-dir|--signed-hap|--output|--device|--profile|--hdc|--method|--keystore|--cert|--profile-file|--key-alias|--sign-alg)
      if (($# < 2)) || [[ -z "$2" || "$2" == --* ]]; then
        printf 'app-installer: missing value for %s\n' "$1" >&2; usage >&2; exit 2
      fi
      key="$1"; value="$2"; shift 2
      case "$key" in
        --hap) hap="$value" ;;
        --bundle-id) bundle_id="$value" ;;
        --app-name) app_name="$value" ;;
        --module) module="$value" ;;
        --ability) ability="$value" ;;
        --project-dir) project_dir="$value" ;;
        --signed-hap|--output) signed_hap="$value" ;;
        --device) device="$value" ;;
        --profile) profile_arg="$value" ;;
        --hdc) hdc_bin="$value" ;;
        --method) method="$value" ;;
        --keystore) keystore="$value" ;;
        --cert) cert="$value" ;;
        --profile-file) profile_file="$value" ;;
        --key-alias) key_alias="$value" ;;
        --sign-alg) sign_alg="$value" ;;
      esac
      ;;
    --sign-only) sign_only=1; shift ;;
    --no-start) start_app=0; ability=; shift ;;
    --no-browser) open_browser=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'app-installer: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$method" in
  auto|hdc|sideload) ;;
  *) die "invalid --method: $method (use auto, hdc or sideload)" 2 ;;
esac
if [[ -n "$bundle_id" && ! "$bundle_id" =~ ^[A-Za-z][A-Za-z0-9_.]*$ ]] || [[ ! "$module" =~ ^[A-Za-z][A-Za-z0-9_.-]*$ ]]; then
  die 'invalid bundle ID or module name' 2
fi
if [[ -n "$ability" && ! "$ability" =~ ^[A-Za-z][A-Za-z0-9_.-]*$ ]]; then
  die 'invalid ability name' 2
fi
if [[ -n "$keystore" ]]; then
  if [[ -n "$profile_arg" ]]; then die '--keystore and --profile are mutually exclusive' 2; fi
  if [[ -z "$cert" || -z "$profile_file" || -z "$key_alias" ]]; then
    die '--keystore needs --cert, --profile-file and --key-alias' 2
  fi
fi

hdc_cmd() {
  if [[ -n "$device" ]]; then "$hdc_bin" -t "$device" "$@"; else "$hdc_bin" "$@"; fi
}

connected_targets() {
  "$hdc_bin" list targets -v 2>/dev/null | awk '{for (i=2; i<=NF; i++) if ($i == "Connected") {print $1; break}}'
}

# Sets $device to the one connected hdc target, or exits with guidance.
resolve_device() {
  [[ -z "$device" ]] || return 0
  local targets count local_port
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
    die 'no connected hdc target; connect and unlock the device, or pass --device.'
  elif ((count > 1)); then
    printf 'app-installer: %s hdc targets attached; pass --device <connect-key>:\n' "$count" >&2
    printf '%s\n' "$targets" | sed 's/^/  /' >&2
    exit 2
  fi
  device="$targets"
}

home="${HOME:?HOME must be set}"
# Projects created before the rename live under ~/.hap-installer; keep using
# that directory only while the new one does not exist yet.
projects_root="$home/.app-installer/projects"
if [[ ! -d "$projects_root" && -d "$home/.hap-installer/projects" ]]; then
  projects_root="$home/.hap-installer/projects"
fi

# Whole days left on the local debug profile of a signing project; prints
# nothing when unknown.
profile_days_left() {
  [[ -n "${DEVECO_CLI_JS:-}" && -f "$1/build-profile.json5" ]] || return 0
  node "$prepare" --expiry "$1/build-profile.json5" 2>/dev/null || true
}

warn_profile_expiry() {
  local days
  days="$(profile_days_left "$1")"
  [[ "$days" =~ ^-?[0-9]+$ ]] || return 0
  if ((days < 0)); then
    printf '%s\n' 'app-installer: WARN: the debug profile has expired; apps signed with it will not start.' >&2
  elif ((days < 7)); then
    printf 'app-installer: WARN: the debug profile expires in %s day(s); re-run app-installer to refresh it.\n' "$days" >&2
  fi
}

# Opens a URL in the Huawei browser through the ability manager, the same way
# the tap's magpie port does. /bin/aa is preferred over /usr/bin/aa, which is a
# zsh wrapper around it. Failure is never fatal: the login URL is also printed,
# so it can be opened by hand.
open_url() {
  local aa="${HAP_INSTALLER_AA:-/bin/aa}"
  if [[ ! -x "$aa" ]]; then aa="$(command -v aa 2>/dev/null)" || return 1; fi
  "$aa" start -b com.huawei.hmos.browser -a MainAbility -U "$1" >/dev/null 2>&1
}

# Runs `devecocli auth login`. The CLI cannot open a browser on OpenHarmony: it
# prints the login URL and then waits for the callback. Watch its output and
# open the first URL that shows up, while still passing every line through.
login_with_browser() {
  local line opened=0 url_re='https?://[A-Za-z0-9._~:/?#@!$&*+,;=%-]+'
  if ((!open_browser)); then devecocli auth login; return; fi
  devecocli auth login 2>&1 | while IFS= read -r line; do
    printf '%s\n' "$line"
    if ((!opened)) && [[ "$line" =~ $url_re ]]; then
      opened=1
      if open_url "${BASH_REMATCH[0]}"; then
        printf '%s\n' 'Opened the login page in your browser; finish signing in there.'
      else
        printf '%s\n' 'Could not open the browser automatically; open the link above by hand.'
      fi
    fi
  done
}

# --- Installation backends ----------------------------------------------------
# The system has not yet published how HAP sideloading works (signature
# requirements, entry point, confirmation prompts). Until it does, hdc is the
# only backend that is known to work.
sideload_available() { return 1; }

install_via_sideload() {
  die 'system sideloading is not available in this version; use --method hdc (or auto).'
}

install_via_hdc() {
  # parts and remote stay global: the EXIT trap below runs after this function
  # has returned, when locals no longer exist.
  local tmp_parent name part install_output start_output
  local -a remote_parts=()
  tmp_parent="${TMPDIR:-$home/.cache}"
  mkdir -p "$tmp_parent"
  parts=$(mktemp -d "$tmp_parent/app-installer.XXXXXX")
  remote="app-installer-$$"
  cleanup() {
    hdc_cmd shell "rm -f /data/local/tmp/$remote-part-* /data/local/tmp/$remote.hap" >/dev/null 2>&1 || true
    rm -rf "$parts"
  }
  trap cleanup EXIT
  split -b 10000000 "$signed_hap" "$parts/part-"
  printf 'Uploading %s to %s\n' "$(basename "$signed_hap")" "$device"
  hdc_cmd shell "rm -f /data/local/tmp/$remote-part-*"
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
    die 'device did not report successful installation.'
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
}

# --- Subcommands that do not sign -------------------------------------------------
require_hdc() {
  command -v "$hdc_bin" >/dev/null 2>&1 || [[ -x "$hdc_bin" ]] || die "required command not found: $hdc_bin"
}

case "$cmd" in
  uninstall|info)
    [[ -n "$bundle_id" ]] || { usage >&2; exit 2; }
    require_hdc
    resolve_device
    if [[ "$cmd" == uninstall ]]; then
      out=$(hdc_cmd shell "bm uninstall -n $bundle_id" 2>&1) || { printf '%s\n' "$out" >&2; exit 1; }
      printf '%s\n' "$out"
      printf '%s\n' "$out" | grep -qiE 'uninstall bundle successfully|^success' ||
        die 'device did not report successful uninstallation.'
    else
      out=$(hdc_cmd shell "bm dump -n $bundle_id" 2>&1) || { printf '%s\n' "$out" >&2; exit 1; }
      printf '%s\n' "$out" | grep -E '"(bundleName|versionName|vendor|installTime|updateTime|appDistributionType|appProvisionType)"' ||
        printf '%s\n' "$out"
      days="$(profile_days_left "$projects_root/$bundle_id")"
      [[ -z "$days" ]] || printf 'debug profile days left: %s\n' "$days"
    fi
    exit 0
    ;;
  doctor)
    problems=0
    check() { # label, ok(0/1), hint
      if (($2 == 0)); then printf '  ok       %s\n' "$1"; else printf '  PROBLEM  %s\n           -> %s\n' "$1" "$3"; problems=$((problems + 1)); fi
    }
    echo 'app-installer doctor'
    for tool in node unzip; do
      rc=0; command -v "$tool" >/dev/null 2>&1 || rc=1
      check "$tool available" "$rc" "brew install $tool"
    done
    rc=0; command -v "$hdc_bin" >/dev/null 2>&1 || [[ -x "$hdc_bin" ]] || rc=1
    check "hdc available ($hdc_bin)" "$rc" 'brew reinstall ohos-sdk-toolchains'
    if ((rc == 0)); then
      targets="$(connected_targets || true)"
      n=$(printf '%s\n' "$targets" | awk 'NF' | wc -l | tr -d ' ')
      rc=0; ((n >= 1)) || rc=1
      check "hdc target connected ($n)" "$rc" 'turn on developer mode and wireless debugging, unlock the device, or pass --device'
    fi
    rc=0; status_output=$(devecocli auth status 2>&1) || rc=1
    case "$status_output" in *'Not logged in'*|*'未登录'*) rc=1 ;; esac
    check 'Huawei Developer login' "$rc" 'run: devecocli auth login (not needed with --profile or --keystore)'
    if [[ -d "$projects_root" ]]; then
      for dir in "$projects_root"/*/; do
        [[ -d "$dir" ]] || continue
        days="$(profile_days_left "${dir%/}")"
        [[ "$days" =~ ^-?[0-9]+$ ]] || continue
        rc=0; ((days >= 7)) || rc=1
        check "debug profile $(basename "$dir"): $days day(s) left" "$rc" "re-run app-installer for $(basename "$dir") to refresh it"
      done
    fi
    if sideload_available; then echo '  ok       system sideloading available'; else echo '  info     system sideloading not available; installs use hdc'; fi
    if ((problems)); then printf '%s problem(s) found.\n' "$problems"; exit 1; fi
    echo 'All checks passed.'
    exit 0
    ;;
esac

# --- install ------------------------------------------------------------------------
if [[ -z "$hap" || -z "$bundle_id" ]]; then usage >&2; exit 2; fi
if [[ ! -f "$hap" ]]; then printf 'app-installer: HAP not found: %s\n' "$hap" >&2; exit 1; fi

use_hdc=1
if ((sign_only)); then
  use_hdc=0
elif [[ "$method" == sideload ]]; then
  sideload_available || install_via_sideload
  use_hdc=0
elif [[ "$method" == auto ]] && sideload_available; then
  use_hdc=0
fi

tools=(node unzip "$HAP_INSTALLER_SIGNER" "$HAP_SIGN_TOOL")
if ((use_hdc)); then tools+=("$hdc_bin"); fi
for tool in "${tools[@]}"; do
  if ! command -v "$tool" >/dev/null 2>&1 && [[ ! -x "$tool" ]]; then
    printf 'app-installer: required command not found: %s\n' "$tool" >&2; exit 1
  fi
done

# Validate the actual artifact before any account operation or upload.
node "$prepare" "$hap" "$bundle_id"

if ((use_hdc)); then resolve_device; fi

app_name="${app_name:-${bundle_id##*.}}"
project_dir="${project_dir:-$projects_root/$bundle_id}"
signed_hap="${signed_hap:-${TMPDIR:-$home/.cache}/app-installer/signed/$bundle_id.hap}"
profile="${profile_arg:-$project_dir/build-profile.json5}"
if [[ "$hap" -ef "$signed_hap" ]]; then
  printf '%s\n' 'app-installer: input and output HAP paths must differ.' >&2; exit 2
fi

sign_args=(--hap "$hap" --output "$signed_hap")
if [[ -n "$keystore" ]]; then
  # The caller's own material: no DevEco account, project or profile generation.
  printf '%s\n' "Signing with the given keystore: $keystore"
  sign_args+=(--keystore "$keystore" --cert "$cert" --profile-file "$profile_file" --key-alias "$key_alias")
  if [[ -n "$sign_alg" ]]; then sign_args+=(--sign-alg "$sign_alg"); fi
elif [[ -n "$profile_arg" ]]; then
  # A caller-supplied profile (e.g. one carrying ACLs) is used as is: running
  # `signature generate` here would replace it with an auto-signed profile
  # that lacks those permissions.
  if [[ ! -f "$profile" ]]; then printf 'app-installer: signing profile not found: %s\n' "$profile" >&2; exit 1; fi
  printf '%s\n' "Signing with the given profile: $profile"
  sign_args+=(--profile "$profile")
else
  status_output=$(devecocli auth status 2>&1) || {
    printf '%s\n' 'app-installer: could not check Huawei Developer login status.' >&2; exit 1
  }
  case "$status_output" in
    *'Not logged in'*|*'未登录'*)
      printf '%s\n' 'A Huawei Developer account login is required; opening DevEco CLI login.'
      login_with_browser
      status_output=$(devecocli auth status 2>&1) || {
        printf '%s\n' 'app-installer: could not verify Huawei Developer login.' >&2; exit 1
      }
      case "$status_output" in *'Not logged in'*|*'未登录'*) printf '%s\n' 'app-installer: login was not completed.' >&2; exit 1 ;; esac
      ;;
  esac
  if [[ ! -f "$project_dir/AppScope/app.json5" ]]; then
    if [[ -e "$project_dir" ]]; then printf 'app-installer: incomplete signing project: %s\n' "$project_dir" >&2; exit 1; fi
    mkdir -p "$(dirname "$project_dir")"
    devecocli create --project-path "$project_dir" --app-name "$app_name" --bundle-name "$bundle_id"
  fi
  if [[ ! -f "$profile" ]]; then printf 'app-installer: missing signing profile: %s\n' "$profile" >&2; exit 1; fi

  node "$prepare" "$hap" "$bundle_id" "$project_dir"

  printf '%s\n' 'Generating or refreshing the local debug profile for connected devices.'
  (cd "$project_dir" && devecocli signature generate --product default)
  warn_profile_expiry "$project_dir"
  sign_args+=(--profile "$profile")
fi
mkdir -p "$(dirname "$signed_hap")"
rm -f "$signed_hap"
# Only the signed output is private: scope 077 to the signer so the chunking
# in install_via_hdc (split + hdc file send) runs under the normal umask. A
# global 077 made split fail with "Permission denied" on hmdfs-backed cache
# directories.
(umask 077; "$HAP_INSTALLER_SIGNER" "${sign_args[@]}")

if ((sign_only)); then
  printf 'Signed HAP: %s\n' "$signed_hap"
  exit 0
fi
if ((use_hdc)); then install_via_hdc; else install_via_sideload; fi
