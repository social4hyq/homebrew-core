#!/usr/bin/env bash
# Shared install flow for the Electron-shell HAP apps in this tap.
#
# It is sourced by each app's own install-desktop.sh (installed next to this
# file as hap-app-install-lib.sh). The flow is the same for every app: stage
# the files that differ per host, put them into a copy of the unsigned HAP,
# optionally swap in the ACL module.json, then sign and install the copy with
# app-installer. The bottle's HAP is never modified.
#
# The sourcing script sets:
#   APP_CMD            command name used in messages (e.g. orca-app)
#   ENV_PREFIX         prefix of the app's wrapper environment (e.g. ORCA_DESKTOP);
#                      the library reads ${ENV_PREFIX}_UNSIGNED_HAP, _MODULE_ACL,
#                      _HDC, _HDC_DEFAULT, _BUNDLE and _APP_NAME
#   BUNDLE_ID_DEFAULT  bundle identifier when ${ENV_PREFIX}_BUNDLE is unset
#   APP_NAME_DEFAULT   signing project name when ${ENV_PREFIX}_APP_NAME is unset
# and defines
#   stage_tree CONFIG TREE   write the per-host files into TREE, which mirrors the
#                            HAP root (e.g. TREE/resources/resfile/resources/app/config.json);
#                            every file under TREE is added to the HAP copy
# It may also set or define (all optional):
#   NEED_CONFIG=0            the app takes no --config (default 1)
#   EXTRA_TOOLS=(curl ...)   tools to require besides node, zip and app-installer
#   KEEP_BASENAME            file name used by --keep (default ${APP_CMD}-signed.hap)
#   MODULE / ABILITY         module and ability to start (default electron / EntryAbility)
#   app_usage_extra          print extra option lines for --help
#   app_parse_option ARGS... recognise an app-specific option; set OPT_SHIFT to the
#                            number of arguments consumed (0 = not recognised)
#   app_prepare              runs after the tool checks, before the ACL check
#
# Contract for callers and `brew test`: the result line goes to stdout,
# progress and diagnostics go to stderr.

set -euo pipefail

NEED_CONFIG="${NEED_CONFIG:-1}"
MODULE="${MODULE:-electron}"
ABILITY="${ABILITY:-EntryAbility}"

log() { printf '%s\n' "$*" >&2; }
die() { log "error: $*"; exit 1; }

# Value of ${ENV_PREFIX}_<SUFFIX>, empty when unset.
envv() {
  local name="${ENV_PREFIX}_$1"
  printf '%s' "${!name-}"
}

hap_app_usage() {
  cat <<EOF
Usage: ${APP_CMD} install [options]

Options:
EOF
  if [ "$NEED_CONFIG" = "1" ]; then
    printf '  --config PATH  Host config written by "%s install".\n' "$APP_CMD"
  fi
  cat <<EOF
  --hap PATH     Unsigned HAP to install (default: the one shipped in the bottle).
  --device ID    hdc target serial (default: the first connected device).
  --no-acl       Install the strong-sandbox variant (fewer permissions).
  --keep         Keep the signed HAP (path printed on success).
EOF
  if declare -F app_usage_extra >/dev/null; then app_usage_extra; fi
  cat <<'EOF'

Installs over hdc. The device must be connected and unlocked; the first ACL
install asks for a Huawei Developer login to generate the local debug profile.
EOF
}

hap_app_install() {
  local bundle_id app_name shell_hap module_acl hdc config="" device=""
  local want_acl=1 keep=0 acl=0 variant OPT_SHIFT

  bundle_id="$(envv BUNDLE)"; bundle_id="${bundle_id:-$BUNDLE_ID_DEFAULT}"
  app_name="$(envv APP_NAME)"; app_name="${app_name:-$APP_NAME_DEFAULT}"
  shell_hap="$(envv UNSIGNED_HAP)"
  module_acl="$(envv MODULE_ACL)"
  hdc="$(envv HDC)"; hdc="${hdc:-$(envv HDC_DEFAULT)}"; hdc="${hdc:-hdc}"

  while [ $# -gt 0 ]; do
    case "$1" in
      --config) config="${2:?--config needs a path}"; shift 2 ;;
      --hap) shell_hap="${2:?--hap needs a path}"; shift 2 ;;
      --device) device="${2:?--device needs an id}"; shift 2 ;;
      --no-acl) want_acl=0; shift ;;
      --keep) keep=1; shift ;;
      -h|--help) hap_app_usage; exit 0 ;;
      *)
        OPT_SHIFT=0
        if declare -F app_parse_option >/dev/null; then app_parse_option "$@"; fi
        [ "$OPT_SHIFT" -gt 0 ] || die "unknown argument: $1"
        shift "$OPT_SHIFT"
        ;;
    esac
  done

  if [ "$NEED_CONFIG" = "1" ]; then
    [ -n "$config" ] && [ -f "$config" ] || die "host config not found: ${config:-<unset>}"
  fi
  [ -n "$shell_hap" ] || die "set ${ENV_PREFIX}_UNSIGNED_HAP or pass --hap"
  [ -f "$shell_hap" ] || die "shell HAP not found: $shell_hap"
  local tool
  for tool in node zip app-installer ${EXTRA_TOOLS[@]+"${EXTRA_TOOLS[@]}"}; do
    command -v "$tool" >/dev/null || die "$tool not found"
  done
  if declare -F app_prepare >/dev/null; then app_prepare; fi

  if [ "$want_acl" = "1" ] && [ -n "$module_acl" ] && [ -f "$module_acl" ]; then
    acl=1
  elif [ "$want_acl" = "1" ]; then
    log "warning: ACL module.json missing; falling back to the strong-sandbox HAP"
  fi

  # The ACL module.json replaces the HAP's own module.json; a bundle mismatch
  # surfaces as an unreadable 9568329 on the device, so catch it here.
  if [ "$acl" = "1" ]; then
    local hap_bundle acl_bundle
    command -v unzip >/dev/null || die "unzip not found"
    hap_bundle="$(unzip -p "$shell_hap" module.json | node -e 'let s=""; process.stdin.on("data",c=>s+=c).on("end",()=>process.stdout.write(JSON.parse(s).app.bundleName))')"
    acl_bundle="$(node -e 'process.stdout.write(JSON.parse(require("node:fs").readFileSync(process.argv[1],"utf8")).app.bundleName)' "$module_acl")"
    [ "$hap_bundle" = "$acl_bundle" ] || die "module-acl.json targets $acl_bundle but the HAP is $hap_bundle"
  fi

  # STAGE_DIR is global on purpose: the EXIT trap runs after this function has
  # returned, when a local variable would already be gone.
  local tree injected signed
  mkdir -p "${TMPDIR:-$HOME/.cache}"
  STAGE_DIR="$(mktemp -d "${TMPDIR:-$HOME/.cache}/${APP_CMD}-inject.XXXXXX")"
  trap 'rm -rf "$STAGE_DIR"' EXIT
  tree="$STAGE_DIR/tree"
  injected="$STAGE_DIR/${APP_CMD}-injected.hap"
  signed="$STAGE_DIR/${APP_CMD}-signed.hap"
  mkdir -p "$tree"
  cp "$shell_hap" "$injected"

  stage_tree "$config" "$tree"
  if [ "$acl" = "1" ]; then cp "$module_acl" "$tree/module.json"; fi
  (cd "$tree" && find . -type f | sed 's|^\./||' | zip -q -X "$injected" -@) || die "could not add files to the HAP"

  local args=(--hap "$injected" --bundle-id "$bundle_id" --app-name "$app_name"
              --module "$MODULE" --ability "$ABILITY" --signed-hap "$signed" --hdc "$hdc")
  if [ -n "$device" ]; then args+=(--device "$device"); fi

  # Stream app-installer's output instead of capturing it: the Huawei login URL
  # and progress lines must reach the terminal while the command is still running.
  log "signing and installing; a first-time Huawei Developer login prints a URL below"
  if ! app-installer "${args[@]}" 2>&1 | sed '/^FileTransfer/d' >&2; then
    die "installation failed"
  fi

  if [ "$keep" = "1" ]; then
    local kept="${TMPDIR:-/tmp}/${KEEP_BASENAME:-${APP_CMD}-signed.hap}"
    cp "$signed" "$kept"
    log "signed HAP kept at $kept"
  fi
  variant="strong-sandbox"
  if [ "$acl" = "1" ]; then variant="ACL"; fi
  printf 'installed (%s, %s)\n' "$bundle_id" "$variant"
}

hap_app_install "$@"
