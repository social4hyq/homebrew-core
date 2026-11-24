#!/usr/bin/env bash
# Download the official Antigravity IDE, assemble a HAP copy and sign/install
# it locally. The bottle ships only the tap-authored shell.
set -euo pipefail

APP_CMD=antigravity-ide-app
ENV_PREFIX=ANTIGRAVITY_IDE_APP
BUNDLE_ID_DEFAULT=com.social4hyq.antigravityide
APP_NAME_DEFAULT=AntigravityIDE
NEED_CONFIG=0
MODULE=electron
ABILITY=EntryAbility

EXTRA_TOOLS=(curl tar sha256sum python3)
VENDOR_TARBALL="${ANTIGRAVITY_IDE_APP_VENDOR_TARBALL:-}"
CLEAN_CACHE=0

log() { printf '%s\n' "$*" >&2; }

app_usage_extra() {
  cat <<'EOF'
  --tarball PATH  Official Antigravity IDE .tar.gz to use instead of downloading.
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
  local cache_dir="${HOME}/.cache/antigravity-ide-app"
  local vendor_json="${ANTIGRAVITY_IDE_APP_VENDOR_JSON:?missing vendor.json}"
  local shell_libexec="${ANTIGRAVITY_IDE_APP_LIBEXEC:?missing libexec path}"
  local url sha version tarfile assembled
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
      log "using the cached Antigravity IDE $version package"
    else
      log "downloading Antigravity IDE $version from Google (~194 MB)..."
      rm -f "$tarfile.part"
      curl -fsSL --retry 5 --retry-all-errors --connect-timeout 30 \
        -o "$tarfile.part" "$url" || { log "error: download failed"; exit 1; }
      sha256_matches "$tarfile.part" "$sha" || { log "error: vendor sha256 mismatch"; exit 1; }
      mv -f "$tarfile.part" "$tarfile"
    fi
  fi

  assembled="$cache_dir/assembled/antigravity-ide-app.hap"
  rm -f "$assembled"

  # Fetch OHOS-native (NAPI) addons that replace the glibc .node files, plus
  # the C++ runtime they link against. The assembler places them in the HAP's
  # libs/ directory — the only dlopen namespace that works on OHOS.
  local native_dir="$cache_dir/vendor/ohos-ports"
  python3 "$shell_libexec/fetch-ports.py" "$native_dir"

  local libcxx=""
  for c in "$HOME/.harmonybrew/opt/ohos-sdk-native/share/ohos-sdk/native/llvm/lib/aarch64-linux-ohos/c++/libc++_shared.so" \
           "$HOME/.harmonybrew/Cellar/ohos-sdk-native/26.0.0.38/llvm/lib/aarch64-linux-ohos/c++/libc++_shared.so"; do
    [ -f "$c" ] && { libcxx="$c"; break; }
  done

  python3 "$shell_libexec/assemble-local-hap.py" \
    "$shell_hap" "$tarfile" "$vendor_json" "$assembled" \
    --native-dir "$native_dir" --libcxx "$libcxx"
  shell_hap="$assembled"
}


# install-lib.sh injects everything written under $2 into a copy of the HAP.
# The official engine reads its own config, so this is only a host-path marker
# (and keeps the injected tree non-empty even with --no-acl).
stage_tree() {
  local dest="$2/resources/resfile/resources/app/antigravity-ide-ohos-host.json"
  mkdir -p "$(dirname "$dest")"
  node - "$dest" <<'JS'
const fs = require("node:fs");
const destination = process.argv[1];
fs.writeFileSync(destination, JSON.stringify({
  home: process.env.HOME || "",
  path: process.env.PATH || "",
  xdgConfigHome: process.env.XDG_CONFIG_HOME || "",
  xdgCacheHome: process.env.XDG_CACHE_HOME || "",
  xdgDataHome: process.env.XDG_DATA_HOME || "",
}) + "\n");
JS
}

. "$(dirname "${BASH_SOURCE[0]}")/hap-app-install-lib.sh"
