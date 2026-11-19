#!/usr/bin/env bash
# Sign and install the GenOffice runtime probe HAP.
#
# The probe takes no host configuration; the flow itself is shared by the HAP
# apps of this tap (hap-app-install-lib.sh, installed next to this script). The
# only per-install file is a stamp inside the app directory, which tells the
# probe report which signed copy is running.
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
