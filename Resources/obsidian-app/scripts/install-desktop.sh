#!/usr/bin/env bash
# Inject the vendor's Obsidian app package into the shell HAP, sign and install.
#
# The shell HAP never contains Obsidian code: it ships the Electron runtime and
# a small host (scheme registration, @electron/remote, sandbox paths). The app
# package is fetched from Obsidian's official release at install time, checked
# against the pinned digest, injected into a copy of the HAP, and only then
# signed. Bottles therefore carry no closed-source bytes.
#
# The default variant is the weak sandbox: the HAP requests CUSTOM_SANDBOX,
# READ_WRITE_USER_FILE, READ_PASTEBOARD and the two kernel JIT ACLs, and the
# tap's app-installer generates the matching local debug profile (it drives
# `devecocli signature generate` itself, so no separate toolchain is needed).
# `--no-acl` falls back to the strong sandbox for debugging.
set -euo pipefail

BUNDLE_ID="${OBSIDIAN_DESKTOP_BUNDLE:-com.social4hyq.obsidiandesktop}"
APP_NAME="${OBSIDIAN_DESKTOP_APP_NAME:-Obsidian}"
SHELL_HAP="${OBSIDIAN_DESKTOP_UNSIGNED_HAP:?set OBSIDIAN_DESKTOP_UNSIGNED_HAP}"
HDC="${OBSIDIAN_DESKTOP_HDC:-${OBSIDIAN_DESKTOP_HDC_DEFAULT:-hdc}}"
MODULE_ACL="${OBSIDIAN_DESKTOP_MODULE_ACL:-}"
ASAR_URL="${OBSIDIAN_ASAR_URL:-}"
ASAR_SHA256="${OBSIDIAN_ASAR_SHA256:-}"
ASAR_CACHE="${OBSIDIAN_ASAR_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/obsidian-desktop}"
ASAR_PATH=""
WANT_ACL=1
KEEP=0

usage() {
  cat <<'EOF'
Usage: obsidian-app install [--asar PATH] [--no-acl] [--keep]

  --asar PATH   Use a local obsidian.asar instead of downloading the pinned
                official release.
  --no-acl      Install the strong-sandbox variant (no user folders, no paste,
                no JIT). Debug only.
  --keep        Keep the staged HAP (printed on success).

Installs over hdc. The device must be connected and unlocked; the first run
asks for a Huawei Developer login to generate the local debug profile.
EOF
}

log() { printf '%s\n' "$*" >&2; }
die() { log "error: $*"; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --asar) ASAR_PATH="${2:?--asar needs a path}"; shift 2 ;;
    --no-acl) WANT_ACL=0; shift ;;
    --keep) KEEP=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[ -f "$SHELL_HAP" ] || die "shell HAP not found: $SHELL_HAP"
command -v node >/dev/null || die "node not found"
command -v zip >/dev/null || die "zip not found"
command -v sha256sum >/dev/null || die "sha256sum not found"
command -v app-installer >/dev/null || die "app-installer not found"

# --- app package: official download or a local copy ------------------------
if [ -z "$ASAR_PATH" ]; then
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
    for url in "${urls[@]}"; do
      if curl -fL --retry 2 --connect-timeout 20 -o "$cached.part" "$url"; then
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
  # Compute-and-compare instead of `sha256sum -c --quiet`: the GNU -c
  # spelling is not portable (HarmonyOS ships a busybox/toybox sha256sum that
  # rejects --quiet), and this form works with any implementation.
  verify_checksum() {
    actual="$(sha256sum "$cached" | cut -d' ' -f1)"
    [ "$actual" = "$ASAR_SHA256" ] ||
      die "sha256 mismatch for $cached: expected $ASAR_SHA256, got $actual"
  }

  case "$cached" in
    *.gz)
      [ -n "$ASAR_SHA256" ] || die "OBSIDIAN_ASAR_SHA256 is not set"
      verify_checksum
      gzip -dc "$cached" > "$ASAR_CACHE/obsidian.asar"
      ;;
    *)
      [ -n "$ASAR_SHA256" ] || die "OBSIDIAN_ASAR_SHA256 is not set"
      verify_checksum
      cp "$cached" "$ASAR_CACHE/obsidian.asar"
      ;;
  esac
  ASAR_PATH="$ASAR_CACHE/obsidian.asar"
fi
[ -f "$ASAR_PATH" ] || die "app package not found: $ASAR_PATH"
head -c 4 "$ASAR_PATH" | od -An -tu4 | grep -q '^ *4$' || die "not an asar file: $ASAR_PATH"

ACL=0
if [ "$WANT_ACL" = "1" ]; then
  if [ -n "$MODULE_ACL" ] && [ -f "$MODULE_ACL" ]; then
    ACL=1
  else
    log "warning: ACL module.json missing; falling back to the strong-sandbox HAP"
  fi
fi

# The ACL module.json replaces the HAP's own module.json. If it was generated
# for a different bundle the signature check fails with 9568329 on the device,
# which is hard to read back; catch it here.
if [ "$ACL" = "1" ]; then
  hap_bundle="$(unzip -p "$SHELL_HAP" module.json | node -e 'let s=""; process.stdin.on("data",c=>s+=c).on("end",()=>process.stdout.write(JSON.parse(s).app.bundleName))')"
  acl_bundle="$(node -e 'process.stdout.write(JSON.parse(require("node:fs").readFileSync(process.argv[1],"utf8")).app.bundleName)' "$MODULE_ACL")"
  if [ "$hap_bundle" != "$acl_bundle" ]; then
    die "module-acl.json targets $acl_bundle but the HAP is $hap_bundle; regenerate module-acl.json"
  fi
fi

# --- stage: inject the app package (and the ACL module.json) ----------------
stage="$(mktemp -d "${TMPDIR:-$HOME/.cache}/obsidian-desktop-inject.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
injected="$stage/obsidian-desktop-injected.hap"
signed="$stage/obsidian-desktop-signed.hap"
cp "$SHELL_HAP" "$injected"
mkdir -p "$stage/tree/resources/resfile/resources/app"
cp "$ASAR_PATH" "$stage/tree/resources/resfile/resources/app/obsidian.asar"
log "injecting $(basename "$ASAR_PATH") into the shell HAP"
if [ "$ACL" = "1" ]; then
  cp "$MODULE_ACL" "$stage/tree/module.json"
  (cd "$stage/tree" && zip -q -X "$injected" module.json resources/resfile/resources/app/obsidian.asar)
else
  (cd "$stage/tree" && zip -q -X "$injected" resources/resfile/resources/app/obsidian.asar)
fi

# Stream app-installer's output instead of capturing it: the Huawei login URL
# and progress lines must reach the terminal while the command is still running.
log "signing and installing; a first-time Huawei Developer login prints a URL below"
if ! app-installer --hap "$injected" --bundle-id "$BUNDLE_ID" \
    --app-name "$APP_NAME" --module electron --ability EntryAbility \
    --signed-hap "$signed" --hdc "$HDC" 2>&1 | sed '/^FileTransfer/d' >&2; then
  die "installation failed"
fi

if [ "$KEEP" = "1" ]; then
  keep="${TMPDIR:-/tmp}/obsidian-desktop-signed.hap"
  cp "$signed" "$keep"
  log "signed HAP kept at $keep"
fi
log "installed ($BUNDLE_ID, $([ "$ACL" = "1" ] && echo ACL || echo strong-sandbox))"
