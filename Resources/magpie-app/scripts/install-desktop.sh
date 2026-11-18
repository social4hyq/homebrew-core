#!/usr/bin/env bash
# Inject the host settings into the Magpie shell HAP, sign it and install it.
#
# The bottle HAP is unsigned and carries only a placeholder config.json; this
# script writes the real settings (the host `magpie` binary the shell starts and
# the host environment that binary needs) into a copy of the HAP, optionally
# swaps in the ACL module.json, and signs it with a locally generated debug
# profile through app-installer. The flow itself is shared by the HAP apps of
# this tap (hap-app-install-lib.sh, installed next to this script); only what is
# specific to Magpie is written here.
#
# The default variant is the ACL one (CUSTOM_SANDBOX and READ_WRITE_USER_FILE let
# the shell start the host binary and reach the host profile). --no-acl installs
# the strong-sandbox variant, which cannot start the binary and waits for a
# `magpie web` started by hand; it carries the same config.json.
set -euo pipefail

APP_CMD=magpie-app
ENV_PREFIX=MAGPIE_APP
BUNDLE_ID_DEFAULT=com.social4hyq.magpiedesktop
APP_NAME_DEFAULT=MagpieDesktop
# There is no --config file: the settings come from the wrapper environment.
NEED_CONFIG=0

BACKEND=""

app_prepare() {
  BACKEND="${MAGPIE_APP_BIN:?formula did not set the magpie binary path}"
}

# Write the host settings into the HAP tree: $2 is the root of the tree that is
# added to the HAP.
stage_tree() {
  local dest="$2/resources/resfile/resources/app/config.json"
  mkdir -p "$(dirname "$dest")"
  node - "$BACKEND" "$dest" <<'JS'
const fs = require("node:fs");
const [backend, destination] = process.argv.slice(2);
const host = { HOME: process.env.HOME, PATH: process.env.PATH };
for (const key of ["XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_STATE_HOME", "XDG_CACHE_HOME"]) {
  const value = process.env[key] || "";
  if (value.startsWith(host.HOME + "/") || value.startsWith("/storage/")) host[key] = value;
}
fs.writeFileSync(destination, JSON.stringify({ backend, host }) + "\n");
JS
}

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../_shared/hap-app/install-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/hap-app-install-lib.sh"
