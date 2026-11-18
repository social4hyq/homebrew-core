#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo 'Usage: magpie-app install [--no-acl] | start'
}
bundle=com.social4hyq.magpiedesktop
hdc="${MAGPIE_APP_HDC:-${MAGPIE_APP_HDC_DEFAULT:-hdc}}"
case "${1:---help}" in
  start)
    [[ $# == 1 ]] || { usage >&2; exit 2; }
    exec "$hdc" shell aa start -b "$bundle" -a EntryAbility -m electron
    ;;
  install)
    acl=1
    if [[ $# == 2 && "$2" == --no-acl ]]; then acl=0
    elif [[ $# != 1 ]]; then usage >&2; exit 2
    fi

    stage="$(mktemp -d)"
    trap 'rm -rf "$stage"' EXIT
    hap="$stage/magpie-desktop.hap"
    cp "${MAGPIE_APP_HAP:?}" "$hap"
    if ((acl)); then
      entry=resources/resfile/resources/app/config.json
      mkdir -p "$stage/$(dirname "$entry")"
      node - "${MAGPIE_APP_BIN:?}" "$stage/$entry" <<'JS'
const fs = require("node:fs");
const [backend, destination] = process.argv.slice(2);
const host = { HOME: process.env.HOME, PATH: process.env.PATH };
for (const key of ["XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_STATE_HOME", "XDG_CACHE_HOME"]) {
  const value = process.env[key] || "";
  if (value.startsWith(host.HOME + "/") || value.startsWith("/storage/")) host[key] = value;
}
fs.writeFileSync(destination, JSON.stringify({ backend, host }) + "\n");
JS
      cp "${MAGPIE_APP_MODULE_ACL:?}" "$stage/module.json"
      (cd "$stage" && zip -q -X "$hap" "$entry" module.json)
    fi
    app-installer --hap "$hap" --bundle-id "$bundle" --app-name MagpieDesktop \
      --module electron --ability EntryAbility --hdc "$hdc"
    ;;
  -h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
