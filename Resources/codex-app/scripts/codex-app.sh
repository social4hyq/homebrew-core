#!/usr/bin/env bash
set -euo pipefail

APP_BUNDLE_ID=com.social4hyq.chatgpt
APP_MODULE=electron
APP_ABILITY=EntryAbility
HAP=${CHATGPT_APP_UNSIGNED_HAP:?missing unsigned HAP path}
APP_INSTALLER=${CHATGPT_APP_INSTALLER:-app-installer}
HDC=${CHATGPT_APP_HDC:-hdc}
INSTALL_SCRIPT=${CHATGPT_APP_INSTALL_SCRIPT:?missing ChatGPT install script path}

usage() {
  cat <<'EOF'
Usage: codex-app <install|start|uninstall>

  install    Inject host Codex paths, sign, and install ChatGPT
  start      Start the installed ChatGPT app
  uninstall  Remove ChatGPT from the selected device

Set HDC_TARGET to select a connected device when more than one is available.
EOF
}

case ${1:-} in
  install)
    shift
    exec "$INSTALL_SCRIPT" "$@"
    ;;
  start)
    [[ -x "$HDC" ]] || command -v "$HDC" >/dev/null
    args=()
    [[ -n ${HDC_TARGET:-} ]] && args+=(-t "$HDC_TARGET")
    "$HDC" "${args[@]}" shell aa start -a "$APP_ABILITY" -b "$APP_BUNDLE_ID" -m "$APP_MODULE"
    ;;
  uninstall)
    [[ -x "$HDC" ]] || command -v "$HDC" >/dev/null
    args=()
    [[ -n ${HDC_TARGET:-} ]] && args+=(-t "$HDC_TARGET")
    "$HDC" "${args[@]}" shell bm uninstall -n "$APP_BUNDLE_ID"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
