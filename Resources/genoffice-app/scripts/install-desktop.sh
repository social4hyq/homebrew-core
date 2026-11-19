#!/usr/bin/env bash
# Sign and install the GenOffice desktop HAP.
#
# GenOffice takes no host configuration: the shell runs everything inside the
# HAP. The flow itself is shared by the HAP apps of this tap
# (hap-app-install-lib.sh, installed next to this script). The shared flow adds
# the files staged here to a copy of the HAP and fails on an empty tree, so a
# stamp with the install time is staged; it also tells which signed copy is
# installed.
set -euo pipefail

APP_CMD=genoffice-app
ENV_PREFIX=GENOFFICE_DESKTOP
BUNDLE_ID_DEFAULT=com.social4hyq.genoffice
APP_NAME_DEFAULT=GenOffice
NEED_CONFIG=0

stage_tree() {
  local dest="$2/resources/resfile/resources/app/installed-at.txt"
  mkdir -p "$(dirname "$dest")"
  date -u '+%Y-%m-%dT%H:%M:%SZ' >"$dest"
}

# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../_shared/hap-app/install-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/hap-app-install-lib.sh"
