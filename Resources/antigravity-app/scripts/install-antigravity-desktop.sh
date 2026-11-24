#!/usr/bin/env bash
# Download the official Antigravity language server onto the HOST, prepare it
# for OHOS, write its absolute path into the HAP config, then sign/install the
# HAP shell. The HAP never carries the 216 MB vendor binary: the HAP sandbox
# cannot exec binaries under libs/, so the engine runs on the host and the
# shell connects to it over loopback (the codex-app/claude-code-app pattern).
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
  --clean-cache   Remove the cached vendor package and prepared engine first.
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
  local brew_prefix="${ANTIGRAVITY_APP_BREW_PREFIX:-${HOMEBREW_PREFIX:-}}"
  [ -n "$brew_prefix" ] || { log "error: missing Homebrew prefix"; exit 1; }

  local url sha version tarfile unpack engine
  mkdir -p "$cache_dir/vendor"
  [ "$CLEAN_CACHE" != 1 ] || rm -rf "$cache_dir/vendor"
  mkdir -p "$cache_dir/vendor"

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

  # Stable HOST path (never a versioned Cellar path: brew upgrade must not
  # break a running shell). Prepared once, reused across reinstalls.
  local engine_dir="$brew_prefix/var/antigravity-app/$version"
  engine="$engine_dir/language-server.bin"
  mkdir -p "$engine_dir"
  local pending=""
  pending=$(mktemp "$engine_dir/.language-server.XXXXXX")
  trap 'rm -rf "$unpack"; [ -z "$pending" ] || rm -f "$pending"' EXIT
  cp "$unpack/Antigravity-arm64/resources/bin/language_server" "$pending"
  patchelf --set-interpreter "$brew_prefix/opt/glibc/lib/ld-linux-aarch64.so.1" "$pending"
  selfsign "$pending"
  chmod +x "$pending"
  mv -f "$pending" "$engine"
  rm -rf "$unpack"

  # The closed-source engine launches the Google OAuth page with `xdg-open`.
  # HarmonyOS has no xdg-open; provide a wrapper that opens the Haiteai browser
  # via `aa` (the built-in Huawei browser does not support the OAuth flow).
  # Always rewrite it so upgrades replace an older wrapper. It lives on the
  # host PATH that is injected into the HAP config.
  local xdg_open="$brew_prefix/bin/xdg-open"
  cat > "$xdg_open" <<'XDG'
#!/usr/bin/env sh
set -eu
url="${1:-}"
[ -n "$url" ] || exit 2
exec /bin/aa start -b com.haitai.htbrowser -a EntryAbility -U "$url"
XDG
  chmod +x "$xdg_open"

  export ANTIGRAVITY_APP_ENGINE="$engine"
  export ANTIGRAVITY_APP_HOST_HOME="${ANTIGRAVITY_APP_HOST_HOME:-$HOME}"
  export ANTIGRAVITY_APP_HOST_PATH="$brew_prefix/bin:$brew_prefix/sbin:/system/bin:/system/xbin:/usr/bin:/bin:/vendor/bin"
  # The engine must reach oauth2.googleapis.com to exchange the auth code.
  # On this device direct access times out (IPv6); the host uses a local proxy
  # recorded in ~/.app-installer/config. Pass it through to the engine.
  local proxy=""
  if [ -f "$HOME/.app-installer/config" ]; then
    proxy=$(sed -n 's/^https_proxy=//p' "$HOME/.app-installer/config" | head -1)
  fi
  export ANTIGRAVITY_APP_PROXY="${ANTIGRAVITY_APP_PROXY:-$proxy}"
  log "prepared host language server at $engine"
}

# install-lib.sh injects everything written under $2 into a copy of the HAP.
# Write the host engine's absolute path so the shell can spawn it.
stage_tree() {
  local dest="$2/resources/resfile/resources/app/antigravity-host-config.json"
  local vendor_json="${ANTIGRAVITY_APP_VENDOR_JSON:?missing vendor.json}"
  local brew_prefix="${ANTIGRAVITY_APP_BREW_PREFIX:-${HOMEBREW_PREFIX:-}}"
  mkdir -p "$(dirname "$dest")"
  node - "$dest" "$vendor_json" "$brew_prefix" <<'JS'
const fs = require("node:fs");
const path = require("node:path");
const [destination, vendorJson, brewPrefix] = process.argv.slice(2);
const version = JSON.parse(fs.readFileSync(vendorJson, "utf8")).version;
const engine = path.join(brewPrefix, "var", "antigravity-app", version, "language-server.bin");
if (!path.isAbsolute(brewPrefix) || !version) throw new Error("invalid host config inputs");
fs.writeFileSync(destination, JSON.stringify({
  home: process.env.HOME || "",
  engine,
  path: process.env.PATH || "",
  proxy: process.env.ANTIGRAVITY_APP_PROXY || "",
}) + "\n", { mode: 0o600 });
JS
}

. "$(dirname "${BASH_SOURCE[0]}")/hap-app-install-lib.sh"
