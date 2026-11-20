#!/usr/bin/env bash
# Build, sign, and install the local self-start Claude Code Desktop candidate.
# The installer stages host paths into this signed copy; no pairing secret is
# generated or manually exchanged. The ACL-enabled build is for local testing.
set -euo pipefail
APP_BUNDLE_ID=com.social4hyq.claudecode
APP_NAME='Claude_Code'

usage() {
  echo "Usage: $0 INPUT_UNSIGNED_HAP OUTPUT_DIR [--no-acl] [--build-only] [--device HDC_TARGET]" >&2
  echo "          [--deb PATH] [--clean-cache]" >&2
}

if (($# < 2)); then usage; exit 2; fi
INPUT_HAP="$(realpath -- "$1")"
OUT_DIR="$(realpath -m -- "$2")"
shift 2
NO_ACL=0
BUILD_ONLY=0
DEVICE=""
VENDOR_DEB=""
CLEAN_CACHE=0
while (($#)); do
  case "$1" in
    --no-acl) NO_ACL=1; shift ;;
    --build-only) BUILD_ONLY=1; shift ;;
    --device) [[ $# -ge 2 ]] || { usage; exit 2; }; DEVICE="$2"; shift 2 ;;
    --deb) [[ $# -ge 2 ]] || { usage; exit 2; }; VENDOR_DEB="$2"; shift 2 ;;
    --clean-cache) CLEAN_CACHE=1; shift ;;
    *) usage; exit 2 ;;
  esac
done

vendor_cache_dir() {
  printf '%s' "${XDG_CACHE_HOME:-$HOME/.cache}/claude-code-app"
}

record_vendor_failure() { # stage reason detail
  [ -n "${HAP_INSTALLER_RESULT_FILE:-}" ] || return 0
  python3 -c 'import json,os,sys; open(os.environ["HAP_INSTALLER_RESULT_FILE"],"w").write(json.dumps({"v":1,"stage":sys.argv[1],"reason":sys.argv[2],"detail":sys.argv[3][:300]})+"\n")' "$1" "$2" "$3" 2>/dev/null || true
}

deb_sha256() {
  python3 -c 'import hashlib,sys; print(hashlib.file_digest(open(sys.argv[1],"rb"),"sha256").hexdigest())' "$1"
}

prepare_vendor_hap() {
  local stage="$1" vendor_json assembler cache deb out url sha version file
  vendor_json="${CLAUDE_CODE_APP_VENDOR_JSON:?missing Claude vendor.json}"
  assembler="${CLAUDE_CODE_APP_ASSEMBLER:?missing the HAP assembler}"
  cache="$(vendor_cache_dir)/vendor"
  if [ "$CLEAN_CACHE" = "1" ]; then rm -rf "$(vendor_cache_dir)"; fi
  mkdir -p "$cache"
  [ -n "$VENDOR_DEB" ] || command -v curl >/dev/null || { echo "curl not found" >&2; exit 1; }
  read -r url sha version file < <(python3 -c 'import json,sys; v=json.load(open(sys.argv[1])); print(v["url"], v["sha256"], v["version"], v.get("file","claude-desktop.deb"))' "$vendor_json")
  [ -n "$url" ] && [ -n "$sha" ] || { echo "invalid vendor.json: $vendor_json" >&2; exit 1; }
  if [ -n "$VENDOR_DEB" ]; then
    [ -f "$VENDOR_DEB" ] || { echo "--deb not found: $VENDOR_DEB" >&2; exit 1; }
    [ "$(deb_sha256 "$VENDOR_DEB")" = "$sha" ] || { echo "--deb failed the sha256 check: $VENDOR_DEB" >&2; exit 1; }
    deb="$VENDOR_DEB"
  else
    deb="$cache/$sha.deb"
    if [ -f "$deb" ] && [ "$(deb_sha256 "$deb")" = "$sha" ]; then
      echo "using the cached Claude Desktop $version package" >&2
    else
      rm -f "$deb" "$deb.part"
      echo "downloading Claude Desktop $version from Anthropic..." >&2
      curl -fL --retry 3 --retry-delay 2 -C - -o "$deb.part" "$url" ||
        { record_vendor_failure download network "download failed: $url"; echo "download failed: $url" >&2; exit 1; }
      mv "$deb.part" "$deb"
      if [ "$(deb_sha256 "$deb")" != "$sha" ]; then
        rm -f "$deb"
        record_vendor_failure download install-failed "downloaded package failed the sha256 check"
        echo "the downloaded package failed the sha256 check" >&2
        exit 1
      fi
    fi
  fi
  out="$stage/claude-desktop-assembled-unsigned.hap"
  echo "assembling the HAP (this can take a minute)..." >&2
  python3 "$assembler" "$INPUT_HAP" "$deb" "$out" >&2 ||
    { record_vendor_failure assemble install-failed "assembling the HAP failed"; echo "assembling the HAP failed" >&2; exit 1; }
  printf '%s' "$out"
}
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
if [ "$(basename -- "$INPUT_HAP")" = "claude-code-shell-unsigned.hap" ]; then
  INPUT_HAP="$(prepare_vendor_hap "$STAGE")"
fi
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
