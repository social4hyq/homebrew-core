#!/usr/bin/env bash
# Inject the host connection config into the shell HAP, sign it and install it.
#
# The bottle HAP is unsigned and carries only a placeholder config.json; this
# script writes the real connection settings (the host `zcode --web` port and
# the initial workspace) into a copy of the HAP, adds the ACL module.json and
# signs it with a locally generated debug profile through app-installer. The
# flow itself is shared by the HAP apps of this tap (hap-app-install-lib.sh,
# installed next to this script); only what is specific to ZCode is written
# here.
#
# Default variant is the ACL one (the two kernel JIT ACLs keep WebAssembly
# available in the renderer, READ_PASTEBOARD makes paste work). --no-acl
# installs the strong-sandbox variant for debugging.
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
fs.writeFileSync(destination, JSON.stringify({port: config.port, workspace: config.workspace}) + "\n");
JS
}

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../_shared/hap-app/install-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/hap-app-install-lib.sh"
