#!/usr/bin/env bash
# Pair the Multica desktop shell HAP with the host bridge, sign it and install it.
#
# The bottle HAP is unsigned and carries no pairing key. This script has the host
# bridge create (or reuse) its pairing key, adds the key to a copy of the HAP,
# optionally swaps in the ACL module.json, and lets app-installer sign and deploy
# the copy. The flow itself is shared by the HAP apps of this tap
# (hap-app-install-lib.sh, installed next to this script); only the Multica
# pairing is written here.
#
# The default variant is the ACL one (CUSTOM_SANDBOX and READ_WRITE_USER_FILE let
# the shell reach the host profile), signed with the locally generated debug
# profile like the other apps. --no-acl installs the basic variant that asks only
# for INTERNET and GET_NETWORK_INFO.
set -euo pipefail

APP_CMD=multica-app
ENV_PREFIX=MULTICA
BUNDLE_ID_DEFAULT=com.social4hyq.multica
APP_NAME_DEFAULT=MulticaSigning
# There is no host config file to pass in: the bridge owns the pairing key.
NEED_CONFIG=0

HAP_ENTRY="resources/resfile/resources/app/desktop-bridge.json"

# The wrapper hands over the zip of the formula; the library only looks at PATH.
# Append its directory so it cannot shadow a tool that is already on PATH.
if [[ -n "${MULTICA_ZIP:-}" ]]; then
  PATH="$PATH:$(dirname "$MULTICA_ZIP")"
fi

# --acl-profile asked for a signing configuration that carried the ACL permissions.
# The locally generated debug profile grants them, so the option is gone.
app_parse_option() {
  case "$1" in
    --acl-profile) die "--acl-profile is no longer needed: the ACL variant is installed by default (use --no-acl for the basic variant)" ;;
  esac
}

app_prepare() {
  : "${MULTICA_DESKTOP_BRIDGE:?multica formula did not set the bridge path}"
  : "${MULTICA_DESKTOP:?multica formula did not set the desktop launcher path}"
}

# $2 is the root of the tree that is added to the HAP.
stage_tree() {
  local dest="$2/$HAP_ENTRY" config
  config="$("$MULTICA_DESKTOP_BRIDGE" --home "${MULTICA_HOME:-$HOME/.multica}" --init-only)"
  mkdir -p "$(dirname "$dest")"
  cp "$config" "$dest"
  # The app reads its first status at launch; have the bridge up before it opens.
  "$MULTICA_DESKTOP" start --bridge-only >&2
}

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../_shared/hap-app/install-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/hap-app-install-lib.sh"
