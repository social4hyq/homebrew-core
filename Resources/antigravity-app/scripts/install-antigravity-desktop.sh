#!/usr/bin/env bash
# Download the official Antigravity engine, prepare it for OHOS, assemble a HAP
# copy and sign/install it locally. The bottle ships only the tap-authored shell.
set -euo pipefail

APP_CMD=antigravity-app
ENV_PREFIX=ANTIGRAVITY_APP
BUNDLE_ID_DEFAULT=com.social4hyq.antigravity
APP_NAME_DEFAULT=Antigravity
NEED_CONFIG=0
MODULE=electron
ABILITY=EntryAbility

EXTRA_TOOLS=(curl tar sha256sum python3 patchelf selfsign)
VENDOR_TARBALL="${ANTIGRAVITY_APP_VENDOR_TARBALL:-}"
CLEAN_CACHE=0

log() { printf '%s\n' "$*" >&2; }

app_usage_extra() {
  cat <<'EOF'
  --tarball PATH  Official Antigravity .tar.gz to use instead of downloading.
  --clean-cache   Remove the cached vendor package and assembled HAP first.
EOF
}

app_parse_option() {
  case "${1:-}" in
    --tarball) VENDOR_TARBALL="${2:?--tarball needs a path}"; OPT_SHIFT=2 ;;
    --clean-cache) CLEAN_CACHE=1; OPT_SHIFT=1 ;;
    *) OPT_SHIFT=0 ;;
  esac
}

sha256_matches() {
  local got
  got=$(sha256sum "$1" | awk '{print $1}')
  [ "$got" = "$2" ]
}

vendor_value() {
  node -e '
const fs=require("node:fs");
const v=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
process.stdout.write(String(v[process.argv[2]]||""));
' "$1" "$2"
}

app_prepare() {
  local cache_dir="${HOME}/.cache/antigravity-app"
  local vendor_json="${ANTIGRAVITY_APP_VENDOR_JSON:?missing vendor.json}"
  local shell_libexec="${ANTIGRAVITY_APP_LIBEXEC:?missing libexec path}"
  local url sha version tarfile prepared assembled unpack
  mkdir -p "$cache_dir/vendor" "$cache_dir/assembled"
  [ "$CLEAN_CACHE" != 1 ] || rm -rf "$cache_dir/vendor" "$cache_dir/assembled"
  mkdir -p "$cache_dir/vendor" "$cache_dir/assembled"

  url=$(vendor_value "$vendor_json" url)
  sha=$(vendor_value "$vendor_json" sha256)
  version=$(vendor_value "$vendor_json" version)
  [ -n "$url" ] && [ -n "$sha" ] && [ -n "$version" ] || {
    log "error: invalid vendor.json"; exit 1;
  }

  if [ -n "$VENDOR_TARBALL" ]; then
    [ -f "$VENDOR_TARBALL" ] || { log "error: --tarball not found: $VENDOR_TARBALL"; exit 1; }
    sha256_matches "$VENDOR_TARBALL" "$sha" || { log "error: --tarball failed the sha256 check"; exit 1; }
    tarfile="$VENDOR_TARBALL"
  else
    tarfile="$cache_dir/vendor/$sha.tar.gz"
    if [ -f "$tarfile" ] && sha256_matches "$tarfile" "$sha"; then
      log "using the cached Antigravity $version package"
    else
      log "downloading Antigravity $version from Google (~204 MB)..."
      rm -f "$tarfile.part"
      curl -fsSL --retry 5 --retry-all-errors --connect-timeout 30 \
        -o "$tarfile.part" "$url" || { log "error: download failed"; exit 1; }
      sha256_matches "$tarfile.part" "$sha" || { log "error: vendor sha256 mismatch"; exit 1; }
      mv -f "$tarfile.part" "$tarfile"
    fi
  fi

  unpack="$cache_dir/vendor/unpack"
  rm -rf "$unpack"; mkdir -p "$unpack"
  tar -xzf "$tarfile" -C "$unpack" \
    "Antigravity-arm64/resources/bin/language_server"
  prepared="$cache_dir/assembled/language-server.bin"
  cp "$unpack/Antigravity-arm64/resources/bin/language_server" "$prepared"
  local brew_prefix="${ANTIGRAVITY_APP_BREW_PREFIX:-${HOMEBREW_PREFIX:-}}"
  [ -n "$brew_prefix" ] || { log "error: missing Homebrew prefix"; exit 1; }
  patchelf --set-interpreter "$brew_prefix/opt/glibc/lib/ld-linux-aarch64.so.1" "$prepared"
  selfsign "$prepared"

  local prepared_sha
  prepared_sha=$(sha256sum "$prepared" | awk '{print $1}')
  local assemble_pin="$cache_dir/assembled/vendor-pin.json"
  node -e '
const fs=require("node:fs");
fs.writeFileSync(process.argv[1], JSON.stringify({languageServerSha256:process.argv[2]})+"\n");
' "$assemble_pin" "$prepared_sha"

  assembled="$cache_dir/assembled/antigravity-app.hap"
  rm -f "$assembled"
  python3 "$shell_libexec/assemble-local-hap.py" \
    "$shell_hap" "$prepared" "$assemble_pin" "$assembled"
  shell_hap="$assembled"
}

. "$(dirname "${BASH_SOURCE[0]}")/hap-app-install-lib.sh"
