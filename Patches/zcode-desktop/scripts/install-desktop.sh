#!/usr/bin/env bash
# Inject the host connection config into the shell HAP, sign it and install it.
#
# The bottle HAP is unsigned and carries only a placeholder config.json; this
# script writes the real connection settings (the host `zcode --web` port and
# the initial workspace) into a copy of the HAP, adds the ACL module.json and
# signs it with a locally generated debug profile through hap-installer.
#
# Default variant is the ACL one (the two kernel JIT ACLs keep WebAssembly
# available in the renderer, READ_PASTEBOARD makes paste work). --no-acl
# installs the strong-sandbox variant for debugging.
set -euo pipefail

BUNDLE_ID="${ZCODE_DESKTOP_BUNDLE:-com.social4hyq.zcodedesktop}"
APP_NAME="${ZCODE_DESKTOP_APP_NAME:-ZCode}"
SHELL_HAP="${ZCODE_DESKTOP_UNSIGNED_HAP:?set ZCODE_DESKTOP_UNSIGNED_HAP}"
MODULE_ACL="${ZCODE_DESKTOP_MODULE_ACL:-}"
HDC="${ZCODE_DESKTOP_HDC:-${ZCODE_DESKTOP_HDC_DEFAULT:-hdc}}"
HAP_CONFIG="resources/resfile/resources/app/config.json"
CONFIG=""
WANT_ACL=1
KEEP=0

usage() {
  cat <<'EOF'
Usage: zcode-desktop install --config PATH [--no-acl] [--keep]

  --config PATH  Host config written by `zcode-desktop serve` (port, workspace).
  --no-acl       Install the strong-sandbox variant (no JIT, no paste).
  --keep         Keep the signed HAP (path printed on success).

Installs over hdc. The device must be connected and unlocked; the first ACL
install asks for a Huawei Developer login to generate the local debug profile.
EOF
}

log() { printf '%s\n' "$*" >&2; }
die() { log "error: $*"; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --config) CONFIG="${2:?--config needs a path}"; shift 2 ;;
    --hap) SHELL_HAP="${2:?--hap needs a path}"; shift 2 ;;
    --no-acl) WANT_ACL=0; shift ;;
    --keep) KEEP=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[ -n "$CONFIG" ] && [ -f "$CONFIG" ] || die "host config not found: ${CONFIG:-<unset>}"
[ -f "$SHELL_HAP" ] || die "shell HAP not found: $SHELL_HAP"
command -v zip >/dev/null || die "zip not found"
command -v hap-installer >/dev/null || die "hap-installer not found"

port="$(sed -n 's/.*"port"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$CONFIG" | head -1)"
workspace="$(sed -n 's/.*"workspace"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG" | head -1)"
[ -n "$port" ] && [ "$port" -gt 0 ] || die "cannot read the web port from $CONFIG"

ACL=0
if [ "$WANT_ACL" = "1" ] && [ -n "$MODULE_ACL" ] && [ -f "$MODULE_ACL" ]; then
  ACL=1
elif [ "$WANT_ACL" = "1" ]; then
  log "warning: ACL module.json missing; falling back to the strong-sandbox HAP"
fi

# The signing CLI can only issue a complete ACL profile when it can read the
# SDK's permission definitions. Warn early instead of failing after the upload
# with a bare 9568289.
if [ "$ACL" = "1" ]; then
  installer_path="$(command -v hap-installer)"
  toolchain="$(sed -n 's/^COMMAND_LINE_TOOL_PATH="\([^"]*\)".*/\1/p' "$installer_path" | head -1)"
  if [ -n "$toolchain" ] &&
     [ ! -f "$toolchain/sdk/default/openharmony/toolchains/lib/PermissionDefinitions.json" ] &&
     [ ! -f "$toolchain/sdk/default/openharmony/toolchains/lib/permissionDefinitions.json" ]; then
    log "warning: hap-installer's toolchain has no PermissionDefinitions.json;"
    log "the generated profile will miss ACLs and installation will fail with 9568289."
  fi
fi

# The ACL module.json replaces the HAP's own module.json; a bundle mismatch
# surfaces as an unreadable 9568329 on the device, so catch it here.
if [ "$ACL" = "1" ]; then
  hap_bundle="$(unzip -p "$SHELL_HAP" module.json | sed -n 's/.*"bundleName": *"\([^"]*\)".*/\1/p' | head -1)"
  acl_bundle="$(sed -n 's/.*"bundleName": *"\([^"]*\)".*/\1/p' "$MODULE_ACL" | head -1)"
  [ "$hap_bundle" = "$acl_bundle" ] || die "module-acl.json targets $acl_bundle but the HAP is $hap_bundle"
fi

ensure_hdc_target() {
  local connected port hint
  connected() { "$HDC" list targets -v 2>/dev/null | grep -qE '[[:space:]]Connected([[:space:]]|$)'; }
  if connected; then return 0; fi
  port=""
  if command -v param >/dev/null 2>&1; then
    port="$(param get persist.hdc.port 2>/dev/null | tr -d ' \n' || true)"
  fi
  if [ -n "$port" ]; then
    "$HDC" tconn "127.0.0.1:$port" >/dev/null 2>&1 || true
    hint="tried \`hdc tconn 127.0.0.1:$port\`"
  else
    hint="persist.hdc.port could not be read"
  fi
  if ! connected; then
    die "no connected hdc target; enable developer options on this PC, unlock it, then retry ($hint)"
  fi
}

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
injected="$stage/zcode-desktop-injected.hap"
signed="$stage/zcode-desktop-signed.hap"
cp "$SHELL_HAP" "$injected"

mkdir -p "$stage/tree/$(dirname "$HAP_CONFIG")"
printf '{"port":%s,"workspace":"%s"}\n' "$port" "$workspace" > "$stage/tree/$HAP_CONFIG"
log "injecting port $port${workspace:+ (workspace $workspace)}"

if [ "$ACL" = "1" ]; then
  cp "$MODULE_ACL" "$stage/tree/module.json"
  (cd "$stage/tree" && zip -q -X "$injected" module.json "$HAP_CONFIG")
else
  (cd "$stage/tree" && zip -q -X "$injected" "$HAP_CONFIG")
fi

# The signing project must request the same ACLs the HAP declares, because
# hap-installer generates the debug profile from this project.
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

ensure_hdc_target
if ! install_output="$(hap-installer --hap "$injected" --bundle-id "$BUNDLE_ID" \
    --app-name "$APP_NAME" --module electron --ability EntryAbility \
    --signed-hap "$signed" 2>&1)"; then
  printf '%s\n' "$install_output" | grep -v '^FileTransfer' >&2
  case "$install_output" in
    *9568289*)
      log "hint: 9568289 means the debug profile carries no ACLs. hap-installer's"
      log "toolchain must ship PermissionDefinitions.json (tap hap-installer r3+)."
      ;;
  esac
  die "installation failed"
fi
printf '%s\n' "$install_output" | grep -v '^FileTransfer' >&2

if [ "$KEEP" = "1" ]; then
  keep="${TMPDIR:-/tmp}/zcode-desktop-signed.hap"
  cp "$signed" "$keep"
  log "signed HAP kept at $keep"
fi
log "installed and started ($BUNDLE_ID, $([ "$ACL" = "1" ] && echo ACL || echo strong-sandbox))"
