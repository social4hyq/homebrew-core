#!/usr/bin/env bash
set -euo pipefail

BUNDLE_ID="com.social4hyq.deepseekharness"
APP_NAME="DeepSeekHarnessDesktop"
HAP_CONFIG="resources/resfile/resources/app/config.json"

usage() {
  printf '%s\n' 'Usage: install-desktop.sh --hap <unsigned.hap> --config <config.json>' \
    '' 'Injects the dsh path and host environment into the HAP, adds the weak' \
    'sandbox ACLs needed to start dsh web, signs with a local debug profile,' \
    'installs on the connected device, and starts the app.'
}

hap=
config=
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
    -h|--help) usage; exit 0 ;;
    *) printf 'install-desktop: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$hap" && -n "$config" ]] || { usage >&2; exit 2; }
[[ -f "$hap" ]] || { printf 'install-desktop: HAP not found: %s\n' "$hap" >&2; exit 1; }
[[ -f "$config" ]] || { printf 'install-desktop: config not found: %s\n' "$config" >&2; exit 1; }
command -v zip >/dev/null 2>&1 || { printf 'install-desktop: zip not found\n' >&2; exit 1; }

HDC="${DSH_DESKTOP_HDC:-${DSH_DESKTOP_HDC_DEFAULT:-}}"
if [[ -z "$HDC" ]]; then HDC="$(command -v hdc || true)"; fi
if [[ -z "$HDC" || ! -x "$HDC" ]]; then
  printf 'install-desktop: hdc not found; set DSH_DESKTOP_HDC to the ohos-sdk-toolchains hdc binary\n' >&2
  exit 1
fi

port="$(sed -n 's/.*"port":\([0-9][0-9]*\).*/\1/p' "$config")"
if [[ -z "$port" ]]; then
  printf 'install-desktop: cannot parse %s\n' "$config" >&2
  exit 1
fi

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

sanitize_xdg() {
  case "${1:-}" in
    "$HOME"/*|/storage/*) printf '%s' "$1" ;;
    *) printf '' ;;
  esac
}

dsh_bin="$(command -v dsh || true)"
if [[ -z "$dsh_bin" && -n "${DSH_DESKTOP_DSH_BIN:-}" ]]; then dsh_bin="$DSH_DESKTOP_DSH_BIN"; fi
if [[ -z "$dsh_bin" || ! -x "$dsh_bin" ]]; then
  printf 'install-desktop: dsh binary not found\n' >&2
  exit 1
fi

stage="$(mktemp -d "${TMPDIR:-/tmp}/deepseek-harness-desktop-inject.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
injected="$stage/deepseek-harness-desktop-injected.hap"
cp "$hap" "$injected"
mkdir -p "$stage/$(dirname "$HAP_CONFIG")"
printf '{"port":%s,"dsh":"%s","host":{"home":"%s","path":"%s","xdgConfig":"%s","xdgData":"%s","xdgState":"%s"}}\n' \
  "$port" "$(json_escape "$dsh_bin")" "$(json_escape "$HOME")" "$(json_escape "$PATH")" \
  "$(json_escape "$(sanitize_xdg "${XDG_CONFIG_HOME:-}")")" \
  "$(json_escape "$(sanitize_xdg "${XDG_DATA_HOME:-}")")" \
  "$(json_escape "$(sanitize_xdg "${XDG_STATE_HOME:-}")")" > "$stage/$HAP_CONFIG"

clt_cache="${DSH_DESKTOP_CLT_CACHE:-${TMPDIR:-/tmp}/deepseek-harness-desktop-clt/clt}"
prepare_clt() {
  local cache="$1"
  local required=(
    "$cache/.deepseek-harness-desktop-clt-v3"
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
  node_bin="${DSH_DESKTOP_NODE:-${DSH_DESKTOP_NODE_DEFAULT:-}}"
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
  printf '#!/bin/sh\nexec %s "$@"\n' "$hdc_real" > "$cache/sdk/default/openharmony/toolchains/hdc"
  printf '#!/bin/sh\nexec %s "$@"\n' "$sign_tool" > "$cache/sdk/default/openharmony/toolchains/lib/hap-sign-tool"
  printf '#!/bin/sh\nexit 0\n' > "$cache/ohpm/bin/pm-cli.js"
  cp "$cache/ohpm/bin/pm-cli.js" "$cache/hvigor/bin/hvigorw.js"
  chmod 0755 "$cache/node/bin/node" \
             "$cache/sdk/default/openharmony/toolchains/hdc" \
             "$cache/sdk/default/openharmony/toolchains/lib/hap-sign-tool" \
             "$cache/ohpm/bin/pm-cli.js" "$cache/hvigor/bin/hvigorw.js"
  cp "$perm_defs" "$cache/sdk/default/openharmony/toolchains/lib/PermissionDefinitions.json"
  ln -sf PermissionDefinitions.json "$cache/sdk/default/openharmony/toolchains/lib/permissionDefinitions.json"

  api="$(sed -n 's/.*"apiVersion": *"\([^"]*\)".*/\1/p' "$uni_pkg" | head -1)"
  pv="$(sed -n 's/.*"platformVersion": *"\([^"]*\)".*/\1/p' "$uni_pkg" | head -1)"
  ver="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$uni_pkg" | head -1)"
  api="${api:-26}"
  pv="${pv:-26.0.0}"
  ver="${ver:-$pv}"
  printf '{"meta":{"version":"1.0.0"},"data":{"apiVersion":"%s","displayName":"HarmonyOS %s","path":"HarmonyOS-%s","platformVersion":"%s","releaseType":"Release","version":"%s","stage":"Release"}}\n' \
    "$api" "$pv" "$pv" "$pv" "$ver" > "$cache/sdk/default/sdk-pkg.json"
  touch "$cache/.deepseek-harness-desktop-clt-v3"
}

if ! prepare_clt "$clt_cache"; then
  printf 'install-desktop: could not prepare the ACL toolchain from brew node and ohos-sdk-toolchains\n' >&2
  exit 1
fi

module_src="${DSH_DESKTOP_MODULE_ACL:-}"
if [[ -z "$module_src" || ! -f "$module_src" ]]; then
  printf 'install-desktop: ACL module.json missing: %s\n' "$module_src" >&2
  exit 1
fi
cp "$module_src" "$stage/module.json"
(cd "$stage" && zip -q "$injected" module.json "$HAP_CONFIG")

hdc_target_connected() {
  "$HDC" list targets -v 2>/dev/null | grep -qE '[[:space:]]Connected([[:space:]]|$)'
}

ensure_hdc_target() {
  local port hint
  if hdc_target_connected; then return 0; fi
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

sign_project="${HOME}/.hap-installer/projects/${BUNDLE_ID}"
command -v devecocli >/dev/null 2>&1 || {
  printf 'install-desktop: devecocli not found (needed for ACL signing)\n' >&2
  exit 1
}
if [[ ! -f "$sign_project/build-profile.json5" ]]; then
  mkdir -p "$(dirname "$sign_project")"
  devecocli create --project-path "$sign_project" --app-name "$APP_NAME" --bundle-name "$BUNDLE_ID" >/dev/null
fi
module_json5="$sign_project/entry/src/main/module.json5"
if [[ -f "$module_json5" ]]; then
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
signed="$stage/deepseek-harness-desktop-signed.hap"
hap-installer-sign --hap "$injected" --profile "$sign_project/build-profile.json5" --output "$signed" >/dev/null

remote="deepseek-harness-desktop-$$"
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
