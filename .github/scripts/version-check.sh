#!/bin/bash
# Report formulae whose upstream version is newer than the packaged one.
source "$(dirname "$0")/lib.sh"

JSON=$(cbrew "livecheck --tap $TAP --json --newer-only") \
  || { echo "::error::brew livecheck failed"; exit 1; }

COUNT=$(jq 'length' <<< "$JSON")
{
  echo "### version-check"
  if [ "$COUNT" -eq 0 ]; then
    echo "All formulae up to date ✅"
  else
    jq -r '.[] | "- \(.formula): \(.version.current) → \(.version.latest)"' <<< "$JSON"
  fi
} | tee -a "$GITHUB_STEP_SUMMARY"
