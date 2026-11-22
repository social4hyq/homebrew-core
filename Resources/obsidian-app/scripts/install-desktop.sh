#!/usr/bin/env bash
# Inject the vendor's Obsidian app package into the shell HAP, sign and install.
#
# The shell HAP never contains Obsidian code: it ships the Electron runtime and
# a small host (scheme registration, @electron/remote, sandbox paths). The app
# package is fetched from Obsidian's official release at install time, checked
# against the pinned digest, injected into a copy of the HAP, and only then
# signed. Bottles therefore carry no closed-source bytes. The install flow
# itself is shared by the HAP apps of this tap (hap-app-install-lib.sh,
# installed next to this script); only what is specific to Obsidian is written
# here.
#
# The default variant is the weak sandbox: the HAP requests CUSTOM_SANDBOX,
# READ_WRITE_USER_FILE, READ_PASTEBOARD and the two kernel JIT ACLs, and the
# tap's app-installer generates the matching local debug profile (it drives
# `devecocli signature generate` itself, so no separate toolchain is needed).
# `--no-acl` falls back to the strong sandbox for debugging.
set -euo pipefail

APP_CMD=obsidian-app
ENV_PREFIX=OBSIDIAN_DESKTOP
BUNDLE_ID_DEFAULT=com.social4hyq.obsidiandesktop
APP_NAME_DEFAULT=Obsidian
# There is no host config: the only thing that goes into the HAP is the app package.
NEED_CONFIG=0
EXTRA_TOOLS=(sha256sum)
# `--keep` has always written this name; keep it for existing users.
KEEP_BASENAME=obsidian-desktop-signed.hap

ASAR_URL="${OBSIDIAN_ASAR_URL:-}"
ASAR_SHA256="${OBSIDIAN_ASAR_SHA256:-}"
ASAR_CACHE="${OBSIDIAN_ASAR_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/obsidian-desktop}"
ASAR_PATH=""

app_usage_extra() {
  cat <<'EOF'
  --asar PATH    Use a local obsidian.asar instead of downloading the pinned
                 official release.
EOF
}

app_parse_option() {
  case "$1" in
    --asar) ASAR_PATH="${2:?--asar needs a path}"; OPT_SHIFT=2 ;;
  esac
}

# Compute-and-compare instead of `sha256sum -c --quiet`: the GNU -c spelling is
# not portable (HarmonyOS ships a busybox/toybox sha256sum that rejects
# --quiet), and this form works with any implementation.
verify_checksum() {
  local actual
  actual="$(sha256sum "$1" | cut -d' ' -f1)"
  [ "$actual" = "$ASAR_SHA256" ] ||
    die "sha256 mismatch for $1: expected $ASAR_SHA256, got $actual"
}

# --- app package: official download or a local copy ------------------------
app_prepare() {
  if [ -z "$ASAR_PATH" ]; then
    local base cached urls ok url
    mkdir -p "$ASAR_CACHE"
    base="${ASAR_URL##*/}"
    [ -n "$base" ] || die "OBSIDIAN_ASAR_URL is not set"
    cached="$ASAR_CACHE/$base"
    if [ ! -f "$cached" ]; then
      log "downloading $ASAR_URL"
      urls=("$ASAR_URL")
      # Some networks cannot reach GitHub release assets. An opt-in mirror
      # prefix (e.g. https://gh-proxy.com/) is tried second.
      if [ -n "${OBSIDIAN_ASAR_MIRROR:-}" ]; then
        urls+=("${OBSIDIAN_ASAR_MIRROR}${ASAR_URL}")
      fi
      ok=0
      curl_tls_args=()
      if [ "${HAP_INSTALLER_TLS_INSECURE:-0}" = "1" ]; then
        curl_tls_args=(--insecure)
        log "warning: TLS certificate verification is disabled for the vendor download"
      fi
      for url in "${urls[@]}"; do
        if curl "${curl_tls_args[@]}" -fL --retry 2 --connect-timeout 20 -o "$cached.part" "$url"; then
          ok=1
          break
        fi
        log "download failed: $url"
      done
      if [ "$ok" != "1" ]; then
        rm -f "$cached.part"
        log "hint: pass --asar PATH with a local copy of the official package, or set"
        log "      OBSIDIAN_ASAR_URL / OBSIDIAN_ASAR_MIRROR to a reachable mirror."
        die "could not download the app package"
      fi
      mv "$cached.part" "$cached"
    fi
    case "$cached" in
      *.gz)
        [ -n "$ASAR_SHA256" ] || die "OBSIDIAN_ASAR_SHA256 is not set"
        verify_checksum "$cached"
        gzip -dc "$cached" > "$ASAR_CACHE/obsidian.asar"
        ;;
      *)
        [ -n "$ASAR_SHA256" ] || die "OBSIDIAN_ASAR_SHA256 is not set"
        verify_checksum "$cached"
        cp "$cached" "$ASAR_CACHE/obsidian.asar"
        ;;
    esac
    ASAR_PATH="$ASAR_CACHE/obsidian.asar"
  fi
  [ -f "$ASAR_PATH" ] || die "app package not found: $ASAR_PATH"
  head -c 4 "$ASAR_PATH" | od -An -tu4 | grep -q '^ *4$' || die "not an asar file: $ASAR_PATH"
}

# Put the app package into the HAP tree: $2 is the root of the tree that is
# added to the HAP.
stage_tree() {
  mkdir -p "$2/resources/resfile/resources/app"
  cp "$ASAR_PATH" "$2/resources/resfile/resources/app/obsidian.asar"
  log "injecting $(basename "$ASAR_PATH") into the shell HAP"
}

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../_shared/hap-app/install-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/hap-app-install-lib.sh"
