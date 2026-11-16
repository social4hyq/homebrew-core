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
# tap's hap-installer generates the matching local debug profile (it drives
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
Usage: obsidian-desktop install [--asar PATH] [--no-acl] [--keep]

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
command -v zip >/dev/null || die "zip not found"
command -v sha256sum >/dev/null || die "sha256sum not found"
command -v hap-installer >/dev/null || die "hap-installer not found"

ensure_hdc_target() {
  local targets port
  targets="$("$HDC" list targets 2>/dev/null || true)"
  if [ -z "$targets" ] || [ "$targets" = "[Empty]" ]; then
    port="$("$HDC" shell param get persist.hdc.port 2>/dev/null | tr -d ' \n' || true)"
    port="${port:-34561}"
    "$HDC" tconn "127.0.0.1:$port" >/dev/null 2>&1 || true
    targets="$("$HDC" list targets 2>/dev/null || true)"
    if [ -z "$targets" ] || [ "$targets" = "[Empty]" ]; then
      die "no hdc target; enable developer options on this PC, unlock it, then retry (tried 127.0.0.1:$port)"
    fi
  fi
}

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

# ACL profiles are only complete when the signing CLI can read the SDK's
# permission definitions. Warn early instead of letting the device answer with
# a bare 9568289 after a 200 MB upload.
if [ "$ACL" = "1" ]; then
  installer_path="$(command -v hap-installer)"
  toolchain="$(sed -n 's/^COMMAND_LINE_TOOL_PATH="\([^"]*\)".*/\1/p' "$installer_path" | head -1)"
  if [ -n "$toolchain" ] &&
     [ ! -f "$toolchain/sdk/default/openharmony/toolchains/lib/PermissionDefinitions.json" ] &&
     [ ! -f "$toolchain/sdk/default/openharmony/toolchains/lib/permissionDefinitions.json" ]; then
    log "warning: hap-installer's toolchain has no PermissionDefinitions.json;"
    log "the generated profile will miss ACLs and installation will fail with"
    log "9568289. Upgrade hap-installer to the tap build that ships it."
  fi
fi

# The ACL module.json replaces the HAP's own module.json. If it was generated
# for a different bundle the signature check fails with 9568329 on the device,
# which is hard to read back; catch it here.
if [ "$ACL" = "1" ]; then
  hap_bundle="$(unzip -p "$SHELL_HAP" module.json | sed -n 's/.*"bundleName": *"\([^"]*\)".*/\1/p' | head -1)"
  acl_bundle="$(sed -n 's/.*"bundleName": *"\([^"]*\)".*/\1/p' "$MODULE_ACL" | head -1)"
  if [ "$hap_bundle" != "$acl_bundle" ]; then
    die "module-acl.json targets $acl_bundle but the HAP is $hap_bundle; regenerate module-acl.json"
  fi
fi

# --- stage: inject the app package (and the ACL module.json) ----------------
stage="$(mktemp -d)"
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

# --- signing project: request the same ACLs the HAP declares ----------------
# hap-installer generates the debug profile from this project with the bundled
# DevEco CLI, so the permissions have to be here as well as in the HAP.
if [ "$ACL" = "1" ]; then
  command -v devecocli >/dev/null || die "devecocli not found"
  sign_project="${HOME}/.hap-installer/projects/${BUNDLE_ID}"
  if [ ! -f "$sign_project/build-profile.json5" ]; then
    mkdir -p "$(dirname "$sign_project")"
    devecocli create --project-path "$sign_project" --app-name "$APP_NAME" \
      --bundle-name "$BUNDLE_ID" >/dev/null
  fi
  module_json5="$sign_project/entry/src/main/module.json5"
  if [ -f "$module_json5" ]; then
    perms_tmp="$stage/signing-permissions.json5"
    cat > "$perms_tmp" <<'PERMS'
    "requestPermissions": [
      { "name": "ohos.permission.INTERNET" },
      { "name": "ohos.permission.GET_NETWORK_INFO" },
      { "name": "ohos.permission.CUSTOM_SANDBOX" },
      { "name": "ohos.permission.READ_WRITE_USER_FILE" },
      { "name": "ohos.permission.READ_PASTEBOARD" },
      { "name": "ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY" },
      { "name": "ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION" }
    ],
PERMS
    if grep -q '"requestPermissions"' "$module_json5"; then
      sed -i '/"requestPermissions": \[/,/^[[:space:]]*\],/d' "$module_json5"
    fi
    sed -i '/"module": {/r '"$perms_tmp" "$module_json5"
  fi
fi

# --- sign, install, start ---------------------------------------------------
ensure_hdc_target
if ! install_output="$(hap-installer --hap "$injected" --bundle-id "$BUNDLE_ID" \
    --app-name "$APP_NAME" --module electron --ability EntryAbility \
    --signed-hap "$signed" 2>&1)"; then
  printf '%s\n' "$install_output" | grep -v '^FileTransfer' >&2
  case "$install_output" in
    *9568289*)
      log "hint: 9568289 means the debug profile carries no ACLs. hap-installer's"
      log "toolchain must ship PermissionDefinitions.json (tap hap-installer r3+)."
      log "check: ls \$(brew --prefix hap-installer)/libexec/hap-installer-toolchain/sdk/default/openharmony/toolchains/lib"
      ;;
  esac
  die "installation failed"
fi
printf '%s\n' "$install_output" | grep -v '^FileTransfer' >&2

if [ "$KEEP" = "1" ]; then
  keep="${TMPDIR:-/tmp}/obsidian-desktop-signed.hap"
  cp "$signed" "$keep"
  log "signed HAP kept at $keep"
fi
log "installed and started ($BUNDLE_ID, $([ "$ACL" = "1" ] && echo ACL || echo strong-sandbox))"
