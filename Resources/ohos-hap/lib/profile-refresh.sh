#!/usr/bin/env bash
# Prepare vendor-debug signing material via the DevEco CLI. ohos-hap drives an
# explicit refresh only; it never logs in and never runs this from sign/install.
# On success, prints the generated build-profile.json5 path on stdout.
set -euo pipefail

CLI="${OHOS_HAP_VENDOR_CLI:-${DEVECO_CLI:-devecocli}}"
PREPARE="${OHOS_HAP_PREPARE_CJS:-$(dirname "$0")/prepare-profile.cjs}"
HAP=""
BUNDLE=""
PROJECT=""
APP_NAME=""
TIMEOUT="${OHOS_HAP_SIGNGEN_TIMEOUT:-600}"

while (($#)); do
  case "$1" in
    --hap) HAP="$2"; shift ;;
    --bundle-id) BUNDLE="$2"; shift ;;
    --project) PROJECT="$2"; shift ;;
    --app-name) APP_NAME="$2"; shift ;;
    *) printf 'profile-refresh: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done
[ -n "$HAP" ] || { printf 'profile-refresh: --hap is required\n' >&2; exit 2; }
[ -n "$BUNDLE" ] || { printf 'profile-refresh: --bundle-id is required\n' >&2; exit 2; }
[ -n "$PROJECT" ] || { printf 'profile-refresh: --project is required\n' >&2; exit 2; }

if ! command -v "$CLI" >/dev/null 2>&1; then
  printf 'profile-refresh: vendor CLI not found: %s\n' "$CLI" >&2
  printf 'set OHOS_HAP_VENDOR_CLI to the devecocli executable path\n' >&2
  exit 2
fi
[ -f "$HAP" ] || { printf 'profile-refresh: HAP not found: %s\n' "$HAP" >&2; exit 2; }
[ -f "$PREPARE" ] || { printf 'profile-refresh: helper not found: %s\n' "$PREPARE" >&2; exit 2; }

# Login is required for signature generation; never start it implicitly.
status="$("$CLI" auth status 2>&1)" || {
  printf 'profile-refresh: could not read vendor login status\n' >&2
  exit 2
}
case "$status" in
  *'Not logged in'*|*'未登录'*)
    printf 'profile-refresh: Huawei Developer login required; run `ohos-hap auth login` first\n' >&2
    exit 2
    ;;
esac

# Create a signing project for this bundle if absent.
if [ ! -f "$PROJECT/AppScope/app.json5" ]; then
  if [ -e "$PROJECT" ]; then
    printf 'profile-refresh: incomplete signing project: %s\n' "$PROJECT" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$PROJECT")"
  [ -n "$APP_NAME" ] || APP_NAME="${BUNDLE##*.}"
  "$CLI" create --project-path "$PROJECT" --app-name "$APP_NAME" --bundle-name "$BUNDLE"
fi

# Sync the HAP's requested permissions into the project module.json5.
node "$PREPARE" "$HAP" "$BUNDLE" "$PROJECT"

# Generate/refresh the local debug profile. Bounded wait; fail closed.
runner=()
if command -v timeout >/dev/null 2>&1; then
  runner=(timeout "$TIMEOUT")
fi
profile_output="$(cd "$PROJECT" && "${runner[@]}" "$CLI" signature generate --product default 2>&1)" || {
  printf '%s\n' "$profile_output" >&2
  printf 'profile-refresh: devecocli signature generate failed\n' >&2
  exit 1
}
printf '%s\n' "$profile_output" >&2

build_profile="$PROJECT/build-profile.json5"
[ -f "$build_profile" ] || {
  printf 'profile-refresh: no build-profile.json5 produced\n' >&2
  exit 1
}
printf '%s\n' "$build_profile"
