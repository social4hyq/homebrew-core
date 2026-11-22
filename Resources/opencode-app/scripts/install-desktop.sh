#!/usr/bin/env bash
# Stage the host config for the OpenCode shell HAP, sign it and install it.
#
# The bottle HAP is unsigned and carries only a placeholder config.json; this
# script writes the host `opencode` binary the shell starts the background
# service with and the host environment that binary needs into a copy of the
# HAP. There is no port or password: the shell connects to the service that
# `opencode service` already runs for the terminal and reads its address and
# password from the service's own state file. It optionally swaps in the ACL
# module.json, and lets app-installer sign and deploy it. The flow itself is
# shared by the HAP apps of this tap (hap-app-install-lib.sh, installed next to
# this script); only what is specific to OpenCode is written here.
#
# The default variant is the ACL one (CUSTOM_SANDBOX and READ_WRITE_USER_FILE let
# the shell spawn the host binary and reach the host profile, READ_PASTEBOARD
# makes paste work). --no-acl installs the strong-sandbox variant.
set -euo pipefail

APP_CMD=opencode-app
ENV_PREFIX=OPENCODE_DESKTOP
BUNDLE_ID_DEFAULT=com.social4hyq.opencodedesktop
APP_NAME_DEFAULT=OpenCodeDesktop

NEED_CONFIG=0
BACKEND=""

# The shell spawns this binary, so it has to exist on the host.
app_prepare() {
  BACKEND="${OPENCODE_DESKTOP_OPENCODE_BIN:-$(command -v opencode || true)}"
  [[ -n "$BACKEND" && -x "$BACKEND" ]] || die "opencode not found"
}

# Write the per-host config into the HAP tree: $1 is unused (this app takes no
# --config), $2 the root of the tree that is added to the HAP.
stage_tree() {
  local dest="$2/resources/resfile/resources/app/config.json"
  mkdir -p "$(dirname "$dest")"
  node - "$BACKEND" "$dest" <<'JS'
const fs = require("node:fs");
const [backend, destination] = process.argv.slice(2);
const home = process.env.HOME;
// Pass the XDG values through as they are: the shell restores them for the
// service it starts and for finding the service's state file, so both match
// what `opencode` run from this terminal uses. An unset variable becomes ""
// (the shell then drops the sandbox's own value).
const xdg = key => process.env[key] || "";
fs.writeFileSync(destination, JSON.stringify({opencode: backend,
  host: {home, path: process.env.PATH, xdgConfig: xdg("XDG_CONFIG_HOME"),
    xdgData: xdg("XDG_DATA_HOME"), xdgState: xdg("XDG_STATE_HOME")}}) + "\n");
JS
}

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../_shared/hap-app/install-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/hap-app-install-lib.sh"
