#!/usr/bin/env bash
# Inject the connection config and the host environment into the unsigned
# desktop HAP, add the weak-sandbox ACL permissions, prepare the signing
# project/CLT for ACL profiles, then sign and install the HAP.
set -euo pipefail

BUNDLE_ID="com.social4hyq.opencodedesktop"
APP_NAME="OpenCodeDesktop"
HAP_CONFIG="resources/resfile/resources/app/config.json"

usage() {
  printf '%s\n' 'Usage: install-desktop.sh --hap <unsigned.hap> --config <config.json> [--no-acl]' \
    '' 'Injects the connection config and host environment into the HAP, adds' \
    'CUSTOM_SANDBOX/READ_WRITE_USER_FILE (weak sandbox) so the shell can start' \
    'opencode serve itself, signs with a local debug profile, installs it on' \
    'the connected device, and starts it.' \
    '--no-acl installs the strong-sandbox variant (no auto-start).'
}

hap=
config=
want_acl=1
while (($#)); do
  case "$1" in
    --hap|--config)
      if (($# < 2)) || [[ -z "$2" || "$2" == --* ]]; then
        printf 'install-desktop: missing value for %s\n' "$1" >&2; usage >&2; exit 2
      fi
      case "$1" in
        --hap) hap="$2" ;;
        --config) config="$2" ;;
      esac
      shift 2
      ;;
    --no-acl) want_acl=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'install-desktop: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$hap" && -n "$config" ]] || { usage >&2; exit 2; }
[[ -f "$hap" ]] || { printf 'install-desktop: HAP not found: %s\n' "$hap" >&2; exit 1; }
[[ -f "$config" ]] || { printf 'install-desktop: config not found: %s\n' "$config" >&2; exit 1; }
command -v zip >/dev/null 2>&1 || { printf 'install-desktop: zip not found\n' >&2; exit 1; }
command -v hap-installer >/dev/null 2>&1 || { printf 'install-desktop: hap-installer not found\n' >&2; exit 1; }

# ohos-sdk-toolchains is keg-only, so brew never links hdc into PATH. The
# formula wrapper injects the absolute path; fall back to PATH for manual runs.
HDC="${OPENCODE_DESKTOP_HDC:-${OPENCODE_DESKTOP_HDC_DEFAULT:-}}"
if [[ -z "$HDC" ]]; then HDC="$(command -v hdc || true)"; fi
if [[ -z "$HDC" || ! -x "$HDC" ]]; then
  printf 'install-desktop: hdc not found; set OPENCODE_DESKTOP_HDC to the ohos-sdk-toolchains hdc binary\n' >&2
  exit 1
fi

port="$(sed -n 's/.*"port":\([0-9][0-9]*\).*/\1/p' "$config")"
password="$(sed -n 's/.*"password":"\([^"]*\)".*/\1/p' "$config")"
if [[ -z "$port" || -z "$password" ]]; then
  printf 'install-desktop: cannot parse %s\n' "$config" >&2
  exit 1
fi

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Only forward XDG overrides that point at host-visible paths; values inside
# another app's sandbox (where the invoking terminal may live) are unreadable
# from the HAP and would split the server from the TUI's database.
sanitize_xdg() {
  case "${1:-}" in
    "$HOME"/*|/storage/*) printf '%s' "$1" ;;
    *) printf '' ;;
  esac
}

opencode_bin="$(command -v opencode || true)"
if [[ -z "$opencode_bin" && -n "${OPENCODE_DESKTOP_OPENCODE_BIN:-}" ]]; then
  opencode_bin="$OPENCODE_DESKTOP_OPENCODE_BIN"
fi
if [[ -z "$opencode_bin" ]]; then
  printf 'install-desktop: opencode binary not found in PATH\n' >&2
  exit 1
fi

stage="$(mktemp -d "${TMPDIR:-/tmp}/opencode-desktop-inject.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
injected="$stage/opencode-desktop-injected.hap"
cp "$hap" "$injected"
mkdir -p "$stage/$(dirname "$HAP_CONFIG")"
{
  printf '{"port":%s,"password":"%s","opencode":"%s",' \
    "$port" "$(json_escape "$password")" "$(json_escape "$opencode_bin")"
  printf '"host":{"home":"%s","path":"%s","xdgConfig":"%s","xdgData":"%s","xdgState":"%s"}}\n' \
    "$(json_escape "$HOME")" "$(json_escape "$PATH")" \
    "$(json_escape "$(sanitize_xdg "${XDG_CONFIG_HOME:-}")")" \
    "$(json_escape "$(sanitize_xdg "${XDG_DATA_HOME:-}")")" \
    "$(json_escape "$(sanitize_xdg "${XDG_STATE_HOME:-}")")"
} > "$stage/$HAP_CONFIG"

# --- ACL support. `devecocli signature generate` only needs node, hdc,
# hap-sign-tool and the SDK's permission definitions — all shipped as signed
# binaries by brew (node, ohos-sdk-toolchains). Copied ELFs are rejected with
# EPERM on OHOS even when their .codesign section survives, so the cache CLT
# wraps the brew binaries in shell scripts and adds the lowercase
# permissionDefinitions.json file the CLI actually reads (the SDK ships only
# the capitalized name). The system CLT under /data/service is not required.
clt_cache="${OPENCODE_DESKTOP_CLT_CACHE:-${TMPDIR:-/tmp}/opencode-desktop-clt/clt}"

prepare_clt() {
  local cache="$1"
  local required=(
    "$cache/.opencode-desktop-clt-v3"
    "$cache/node/bin/node"
    "$cache/sdk/default/sdk-pkg.json"
    "$cache/sdk/default/openharmony/toolchains/hdc"
    "$cache/sdk/default/openharmony/toolchains/lib/hap-sign-tool"
    "$cache/sdk/default/openharmony/toolchains/lib/permissionDefinitions.json"
  )
  local f ok=1
  for f in "${required[@]}"; do
    [[ -e "$f" ]] || { ok=0; break; }
  done
  ((ok)) && return 0

  local node_bin hdc_bin hdc_real tc_prefix sign_tool perm_defs uni_pkg api pv ver
  node_bin="${OPENCODE_DESKTOP_NODE:-${OPENCODE_DESKTOP_NODE_DEFAULT:-}}"
  if [[ -z "$node_bin" ]]; then node_bin="$(command -v node || true)"; fi
  [[ -n "$node_bin" ]] || return 1
  hdc_bin="$HDC"
  hdc_real="$(readlink -f "$hdc_bin" 2>/dev/null || printf '%s' "$hdc_bin")"
  tc_prefix="$(dirname "$HDC")"
  if [[ ! -x "$tc_prefix/lib/hap-sign-tool" ]]; then
    tc_prefix="$(brew --prefix ohos-sdk-toolchains 2>/dev/null || true)"
  fi
  sign_tool="$tc_prefix/lib/hap-sign-tool"
  perm_defs="$tc_prefix/lib/PermissionDefinitions.json"
  uni_pkg="$tc_prefix/oh-uni-package.json"
  [[ -x "$sign_tool" && -f "$perm_defs" && -f "$uni_pkg" ]] || return 1

  rm -rf "$cache"
  mkdir -p "$cache/node/bin" "$cache/ohpm/bin" "$cache/hvigor/bin" \
           "$cache/sdk/default/openharmony/toolchains/lib"
  printf '#!/bin/sh\nexec %s "$@"\n' "$node_bin" > "$cache/node/bin/node"
  printf '#!/bin/sh\nexec %s "$@"\n' "$hdc_real" \
    > "$cache/sdk/default/openharmony/toolchains/hdc"
  printf '#!/bin/sh\nexec %s "$@"\n' "$sign_tool" \
    > "$cache/sdk/default/openharmony/toolchains/lib/hap-sign-tool"
  # Only existence-checked by the CLI for signature generation.
  printf '#!/bin/sh\nexit 0\n' > "$cache/ohpm/bin/pm-cli.js"
  cp "$cache/ohpm/bin/pm-cli.js" "$cache/hvigor/bin/hvigorw.js"
  chmod 0755 "$cache/node/bin/node" \
             "$cache/sdk/default/openharmony/toolchains/hdc" \
             "$cache/sdk/default/openharmony/toolchains/lib/hap-sign-tool" \
             "$cache/ohpm/bin/pm-cli.js" "$cache/hvigor/bin/hvigorw.js"
  cp "$perm_defs" "$cache/sdk/default/openharmony/toolchains/lib/PermissionDefinitions.json"
  ln -sf PermissionDefinitions.json \
    "$cache/sdk/default/openharmony/toolchains/lib/permissionDefinitions.json"

  api="$(sed -n 's/.*"apiVersion": *"\([^"]*\)".*/\1/p' "$uni_pkg" | head -1)"
  pv="$(sed -n 's/.*"platformVersion": *"\([^"]*\)".*/\1/p' "$uni_pkg" | head -1)"
  ver="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$uni_pkg" | head -1)"
  api="${api:-26}"
  pv="${pv:-26.0.0}"
  ver="${ver:-$pv}"
  printf '{"meta":{"version":"1.0.0"},"data":{"apiVersion":"%s","displayName":"HarmonyOS %s","path":"HarmonyOS-%s","platformVersion":"%s","releaseType":"Release","version":"%s","stage":"Release"}}\n' \
    "$api" "$pv" "$pv" "$pv" "$ver" > "$cache/sdk/default/sdk-pkg.json"
  touch "$cache/.opencode-desktop-clt-v3"
}

acl=0
if ((want_acl)) && prepare_clt "$clt_cache"; then
  acl=1
else
  printf 'install-desktop: ACL toolchain unavailable; installing the strong-sandbox variant (the shell will not auto-start the backend)\n' >&2
fi

module_src="${OPENCODE_DESKTOP_MODULE_ACL:-}"
if ((acl)); then
  if [[ -z "$module_src" || ! -f "$module_src" ]]; then
    printf 'install-desktop: ACL module.json missing; disabling ACL install\n' >&2
    acl=0
  fi
fi
if ((acl)); then
  cp "$module_src" "$stage/module.json"
  (cd "$stage" && zip -q "$injected" module.json "$HAP_CONFIG")
else
  (cd "$stage" && zip -q "$injected" "$HAP_CONFIG")
fi

# A local install needs a Connected device in hdc. On the OHOS PC the device
# endpoint is loopback; a fresh machine may not be connected yet, and a dropped
# link leaves the target listed as Offline, so a listed target is not enough.
hdc_target_connected() {
  "$HDC" list targets -v 2>/dev/null | grep -qE '[[:space:]]Connected([[:space:]]|$)'
}

ensure_hdc_target() {
  local port hint
  if hdc_target_connected; then
    return 0
  fi
  # The local device-side daemon port lives in persist.hdc.port and changes
  # between boots, so it is read on every run and never assumed.
  port=""
  if command -v param >/dev/null 2>&1; then
    port="$(param get persist.hdc.port 2>/dev/null | tr -d ' \n')"
  fi
  if [[ -n "$port" ]]; then
    "$HDC" tconn "127.0.0.1:$port" >/dev/null 2>&1 || true
    hint="tried \`hdc tconn 127.0.0.1:$port\`"
  else
    hint="persist.hdc.port could not be read"
  fi
  if ! hdc_target_connected; then
    printf 'install-desktop: no connected hdc target; enable developer options and USB debugging on this PC, unlock it, then retry (%s)\n' "$hint" >&2
    return 1
  fi
}

# --- Patch the hap-installer signing project so its `devecocli signature
# generate` asks AGC for the two restricted permissions; the debug profile is
# issued on the spot (no approval wait), but the release path still needs the
# normal AGC review.
sign_project="${HOME}/.hap-installer/projects/${BUNDLE_ID}"
if ((acl)); then
  command -v devecocli >/dev/null 2>&1 || {
    printf 'install-desktop: devecocli not found (needed for ACL signing)\n' >&2
    exit 1
  }
  if [[ ! -f "$sign_project/build-profile.json5" ]]; then
    mkdir -p "$(dirname "$sign_project")"
    devecocli create --project-path "$sign_project" --app-name "$APP_NAME" \
      --bundle-name "$BUNDLE_ID" >/dev/null
  fi
  module_json5="$sign_project/entry/src/main/module.json5"
  if [[ -f "$module_json5" ]]; then
    # Rewrite the permission list deterministically. The two kernel ACLs
    # enable JIT: without them the shell forces Electron into --jitless,
    # which also removes WebAssembly and breaks the markdown worker.
    perms_tmp="$stage/signing-permissions.json5"
    cat > "$perms_tmp" <<'PERMS'
    "requestPermissions": [
      { "name": "ohos.permission.INTERNET" },
      { "name": "ohos.permission.GET_NETWORK_INFO" },
      { "name": "ohos.permission.CUSTOM_SANDBOX" },
      { "name": "ohos.permission.READ_WRITE_USER_FILE" },
      { "name": "ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY" },
      { "name": "ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION" }
    ],
PERMS
    if grep -q '"requestPermissions"' "$module_json5"; then
      sed -i '/"requestPermissions": \[/,/^[[:space:]]*\],/d' "$module_json5"
    fi
    sed -i '/"module": {/r '"$perms_tmp" "$module_json5"
  fi

  # hap-installer's own wrapper hardcodes COMMAND_LINE_TOOL_PATH to its
  # bundled minimal toolchain, which silently regenerates the profile
  # without ACLs. Drive the same steps here with the prepared CLT:
  # login check -> signature generate -> sign -> chunked hdc install.
  ensure_hdc_target
  status_output="$(devecocli auth status 2>&1)" || {
    printf 'install-desktop: could not check Huawei Developer login status\n' >&2
    exit 1
  }
  case "$status_output" in
    *'Not logged in'*|*'未登录'*)
      printf 'install-desktop: Huawei Developer login required; opening DevEco CLI login\n'
      devecocli auth login
      ;;
  esac
  (cd "$sign_project" && COMMAND_LINE_TOOL_PATH="$clt_cache" devecocli signature generate --product default)
  command -v hap-installer-sign >/dev/null 2>&1 || {
    printf 'install-desktop: hap-installer-sign not found\n' >&2
    exit 1
  }
  signed="$stage/opencode-desktop-signed.hap"
  hap-installer-sign --hap "$injected" --profile "$sign_project/build-profile.json5" \
    --output "$signed" >/dev/null

  remote="opencode-desktop-$$"
  mkdir -p "$stage/parts"
  split -b 10000000 "$signed" "$stage/parts/part-"
  "$HDC" shell "rm -f /data/local/tmp/$remote-part-*" >/dev/null 2>&1 || true
  for part in "$stage/parts"/part-*; do
    "$HDC" file send "$part" "/data/local/tmp/$remote-$(basename "$part")" >/dev/null
  done
  "$HDC" shell "cat /data/local/tmp/$remote-part-* > /data/local/tmp/$remote.hap"
  "$HDC" shell "aa force-stop $BUNDLE_ID" >/dev/null 2>&1 || true
  if ! install_output="$("$HDC" shell "bm install -p /data/local/tmp/$remote.hap" 2>&1)"; then
    printf '%s\n' "$install_output" >&2
    exit 1
  fi
  printf '%s\n' "$install_output"
  if ! printf '%s\n' "$install_output" | grep -qiE 'install bundle successfully|^success'; then
    printf 'install-desktop: device did not report successful installation\n' >&2
    exit 1
  fi
  "$HDC" shell "rm -f /data/local/tmp/$remote-part-* /data/local/tmp/$remote.hap" >/dev/null 2>&1 || true
  "$HDC" shell "aa start -a EntryAbility -b $BUNDLE_ID -m electron" >/dev/null
  printf 'install-desktop: installed and started %s\n' "$BUNDLE_ID"
else
  ensure_hdc_target
  hap-installer \
    --hap "$injected" \
    --bundle-id "$BUNDLE_ID" \
    --app-name "$APP_NAME" \
    --module electron \
    --ability EntryAbility
fi
