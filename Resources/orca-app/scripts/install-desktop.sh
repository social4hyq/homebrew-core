#!/usr/bin/env bash
# Inject the host connection config into the shell HAP, sign it and install it.
#
# The bottle HAP is unsigned and carries only a placeholder config.json; this
# script writes the real connection settings (the loopback port, the host
# `orca` binary the shell spawns, and the host environment that binary needs)
# into a copy of the HAP, optionally swaps in the ACL module.json, and signs it
# with a locally generated debug profile through app-installer. The flow itself
# is shared by the HAP apps of this tap (hap-app-install-lib.sh, installed next
# to this script); only what is specific to Orca is written here.
#
# The shell starts the runtime server itself, so no pairing URL is baked in: the
# runtime mints a single-use link on each start and the shell reads it from the
# server log.
#
# Default variant is the ACL one (CUSTOM_SANDBOX and READ_WRITE_USER_FILE let the
# shell spawn the host binary and reach the host profile; the two kernel JIT ACLs
# keep WebAssembly available in the renderer, READ_PASTEBOARD makes paste work).
# --no-acl installs the strong-sandbox variant, which then waits for a host
# `orca-app serve`.
set -euo pipefail

APP_CMD=orca-app
ENV_PREFIX=ORCA_DESKTOP
BUNDLE_ID_DEFAULT=com.social4hyq.orca
APP_NAME_DEFAULT=Orca

# Write the per-host config into the HAP tree: $1 is the host config written by
# `orca-app install`, $2 the root of the tree that is added to the HAP.
stage_tree() {
  local dest="$2/resources/resfile/resources/app/config.json"
  mkdir -p "$(dirname "$dest")"
  node - "$1" "$dest" <<'JS'
const fs = require("node:fs");
const [source, destination] = process.argv.slice(2);
const config = JSON.parse(fs.readFileSync(source, "utf8"));
if (!Number.isInteger(config.port) || config.port < 1 || config.port > 65535) throw new Error("invalid server port");
if (typeof config.orca !== "string" || !config.orca.startsWith("/")) throw new Error("invalid orca binary path");
const host = config.host;
if (!host || typeof host !== "object" || typeof host.home !== "string" || !host.home.startsWith("/")) {
  throw new Error("invalid host environment");
}
const pick = (value) => (typeof value === "string" ? value : "");
fs.writeFileSync(destination, JSON.stringify({
  port: config.port,
  orca: config.orca,
  host: {
    home: host.home,
    path: pick(host.path),
    xdgConfig: pick(host.xdgConfig),
    xdgData: pick(host.xdgData),
    xdgState: pick(host.xdgState),
  },
  tray: config.tray !== false,
}) + "\n");
JS
}

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../_shared/hap-app/install-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/hap-app-install-lib.sh"
