#!/usr/bin/env bash
# Build, sign, and install the local self-start Claude Code Desktop candidate.
# The installer stages host paths into this signed copy; no pairing secret is
# generated or manually exchanged. The ACL-enabled build is for local testing.
set -euo pipefail
APP_BUNDLE_ID=com.social4hyq.claudecode
APP_NAME='Claude_Code'

usage() {
  echo "Usage: $0 INPUT_UNSIGNED_HAP OUTPUT_DIR [--no-acl] [--build-only] [--device HDC_TARGET]" >&2
}

if (($# < 2)); then usage; exit 2; fi
INPUT_HAP="$(realpath -- "$1")"
OUT_DIR="$(realpath -m -- "$2")"
shift 2
NO_ACL=0
BUILD_ONLY=0
DEVICE=""
while (($#)); do
  case "$1" in
    --no-acl) NO_ACL=1; shift ;;
    --build-only) BUILD_ONLY=1; shift ;;
    --device) [[ $# -ge 2 ]] || { usage; exit 2; }; DEVICE="$2"; shift 2 ;;
    *) usage; exit 2 ;;
  esac
done
[[ -f "$INPUT_HAP" ]] || { echo "Input HAP not found: $INPUT_HAP" >&2; exit 1; }
command -v python3 >/dev/null
command -v unzip >/dev/null
command -v app-installer >/dev/null

HOME_HOST="${CLAUDE_DESKTOP_HOST_HOME:-$HOME}"
BREW_PREFIX="${HOMEBREW_PREFIX:-$HOME_HOST/.harmonybrew}"
CLAUDE_LAUNCHER="$BREW_PREFIX/opt/claude-code.latest/bin/claude"
[[ -x "$CLAUDE_LAUNCHER" ]] || { echo "Homebrew Claude Code launcher missing: $CLAUDE_LAUNCHER" >&2; exit 1; }
mkdir -p -- "$OUT_DIR"
OUT_DIR="$(cd -- "$OUT_DIR" && pwd -P)"
TMP_PARENT="${TMPDIR:-/data/storage/el2/base/cache}"
mkdir -p -- "$TMP_PARENT"
STAGE="$(mktemp -d "$TMP_PARENT/claude-selfstart.XXXXXX")"
trap 'rm -rf -- "$STAGE"' EXIT
UNSIGNED="$OUT_DIR/claude-code-desktop-selfstart-unsigned.hap"
SIGNED="$OUT_DIR/claude-code-desktop-selfstart-signed.hap"
rm -f -- "$UNSIGNED"
patch_args=("$INPUT_HAP" "$UNSIGNED" --host-home "$HOME_HOST" --brew-prefix "$BREW_PREFIX" --host-path "${PATH:-}")
((NO_ACL)) && patch_args+=(--no-acl)
python3 "$(dirname -- "${BASH_SOURCE[0]}")/patch-code-runtime-hap.py" "${patch_args[@]}"

if ((BUILD_ONLY)); then
  printf 'built unsigned HAP: %s\n' "$UNSIGNED"
  exit 0
fi

install_args=(--hap "$UNSIGNED" --bundle-id "$APP_BUNDLE_ID" --app-name "$APP_NAME" \
  --module electron --ability EntryAbility --signed-hap "$SIGNED")
[[ -n "$DEVICE" ]] && install_args+=(--device "$DEVICE")
app-installer "${install_args[@]}"
