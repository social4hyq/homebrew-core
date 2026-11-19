#!/usr/bin/env bash
# Inject the host connection config into the shell HAP, sign it and install it.
#
# The bottle HAP is unsigned and carries only a placeholder config.json; this
# script writes the real connection settings (the host `zcode --web` port and
# the initial workspace) into a copy of the HAP, adds the ACL module.json and
# signs it with a locally generated debug profile through app-installer. When
# the wrapper sets ZCODE_DESKTOP_LAUNCHER it also bakes in the host `zcode-app`
# path and this shell's HOME/PATH/XDG values, which the shell needs to start
# the service itself. The
# flow itself is shared by the HAP apps of this tap (hap-app-install-lib.sh,
# installed next to this script); only what is specific to ZCode is written
# here.
#
# Default variant is the ACL one (CUSTOM_SANDBOX and READ_WRITE_USER_FILE let
# the shell run the host zcode-app to start the service, the two kernel JIT ACLs
# keep WebAssembly available in the renderer, READ_PASTEBOARD makes paste work).
# --no-acl installs the strong-sandbox variant, which cannot start the service
# and waits for `zcode-app serve`.
set -euo pipefail

APP_CMD=zcode-app
ENV_PREFIX=ZCODE_DESKTOP
BUNDLE_ID_DEFAULT=com.social4hyq.zcodedesktop
APP_NAME_DEFAULT=ZCode
# `--keep` has always written this name; keep it for existing users.
KEEP_BASENAME=zcode-desktop-signed.hap

# Write the per-host config into the HAP tree: $1 is the host config written by
# `zcode-app serve`, $2 the root of the tree that is added to the HAP.
stage_tree() {
  local dest="$2/resources/resfile/resources/app/config.json"
  mkdir -p "$(dirname "$dest")"
  node - "$1" "$dest" <<'JS'
const fs = require("node:fs");
const [source, destination] = process.argv.slice(2);
const config = JSON.parse(fs.readFileSync(source, "utf8"));
if (!Number.isInteger(config.port) || config.port < 1 || config.port > 65535) throw new Error("invalid web port");
if (typeof config.workspace !== "string") throw new Error("invalid workspace");
const out = {port: config.port, workspace: config.workspace};
const launcher = process.env.ZCODE_DESKTOP_LAUNCHER || "";
if (launcher) {
  // The shell runs `<launcher> serve` with the host environment captured here.
  if (!launcher.startsWith("/")) throw new Error("invalid launcher path");
  const home = process.env.HOME;
  if (!home || !home.startsWith("/")) throw new Error("HOME is not set");
  const xdg = key => {
    const value = process.env[key] || "";
    return value.startsWith(home + "/") || value.startsWith("/storage/") ? value : "";
  };
  out.launcher = launcher;
  out.host = {home, path: process.env.PATH, xdgConfig: xdg("XDG_CONFIG_HOME"),
    xdgData: xdg("XDG_DATA_HOME"), xdgState: xdg("XDG_STATE_HOME")};
}
fs.writeFileSync(destination, JSON.stringify(out) + "\n");
JS
}

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../_shared/hap-app/install-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/hap-app-install-lib.sh"
