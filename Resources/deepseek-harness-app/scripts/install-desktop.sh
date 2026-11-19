#!/usr/bin/env bash
# Stage the host config for the DeepSeek Harness shell HAP, sign it and install it.
#
# The bottle HAP is unsigned and carries only a placeholder config.json; this
# script writes the real connection settings (the loopback port, the host `dsh`
# binary the shell spawns and the host environment that binary needs) into a
# copy of the HAP, adds the ACL module.json, and lets app-installer sign and
# deploy it. The flow itself is shared by the HAP apps of this tap
# (hap-app-install-lib.sh, installed next to this script); only what is specific
# to DeepSeek Harness is written here.
#
# The default variant is the ACL one (CUSTOM_SANDBOX and READ_WRITE_USER_FILE let
# the shell spawn the host binary and reach the host profile, READ_PASTEBOARD
# makes paste work). --no-acl installs the strong-sandbox variant.
set -euo pipefail

APP_CMD=deepseek-harness-app
ENV_PREFIX=DSH_DESKTOP
BUNDLE_ID_DEFAULT=com.social4hyq.deepseekharness
APP_NAME_DEFAULT=DeepSeekHarnessDesktop

BACKEND=""

# The shell spawns this binary, so it has to exist on the host.
app_prepare() {
  BACKEND="${DSH_DESKTOP_DSH_BIN:-$(command -v dsh || true)}"
  [[ -n "$BACKEND" && -x "$BACKEND" ]] || die "dsh not found"
}

# Write the per-host config into the HAP tree: $1 is the host config written by
# `dsh-app install`, $2 the root of the tree that is added to the HAP.
stage_tree() {
  local dest="$2/resources/resfile/resources/app/config.json"
  mkdir -p "$(dirname "$dest")"
  node - "$1" "$BACKEND" "$dest" <<'JS'
const fs = require("node:fs");
const [source, backend, destination] = process.argv.slice(2);
const config = JSON.parse(fs.readFileSync(source, "utf8"));
if (!Number.isInteger(config.port) || config.port < 1 || config.port > 65535) throw new Error("invalid port");
const home = process.env.HOME;
const xdg = key => {
  const value = process.env[key] || "";
  return value.startsWith(home + "/") || value.startsWith("/storage/") ? value : "";
};
fs.writeFileSync(destination, JSON.stringify({port: config.port,  dsh: backend,
  host: {home, path: process.env.PATH, xdgConfig: xdg("XDG_CONFIG_HOME"),
    xdgData: xdg("XDG_DATA_HOME"), xdgState: xdg("XDG_STATE_HOME")}}) + "\n");
JS
}

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../_shared/hap-app/install-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/hap-app-install-lib.sh"
