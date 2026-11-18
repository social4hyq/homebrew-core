#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo 'Usage: magpie-app install [--no-acl] [--keep] [--device ID] | start'
}
bundle=com.social4hyq.magpiedesktop
hdc="${MAGPIE_APP_HDC:-${MAGPIE_APP_HDC_DEFAULT:-hdc}}"
case "${1:---help}" in
  start)
    [[ $# == 1 ]] || { usage >&2; exit 2; }
    exec "$hdc" shell aa start -b "$bundle" -a EntryAbility -m electron
    ;;
  install)
    shift
    exec "${MAGPIE_APP_INSTALL_SCRIPT:?formula did not set the install script path}" "$@"
    ;;
  -h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
