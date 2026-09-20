#!/bin/bash
# Report formulae whose upstream version is newer than the packaged one.
source "$(dirname "$0")/lib.sh"

JSON=$(cbrew "livecheck --tap $TAP --json --newer-only") \
  || { echo "::error::brew livecheck failed"; exit 1; }

OUTDATED=$(jq -r '.[] | select(.version.latest != null) | "- \(.formula): \(.version.current) → \(.version.latest)"' <<< "$JSON")
UNCHECKABLE=$(jq -r '.[] | select(.version.latest == null) | "- \(.formula): unable to determine upstream version (add a livecheck block?)"' <<< "$JSON")
{
  echo "### version-check"
  if [ -z "$OUTDATED" ] && [ -z "$UNCHECKABLE" ]; then
    echo "All formulae up to date ✅"
  fi
  if [ -n "$OUTDATED" ]; then
    echo "Outdated:"
    echo "$OUTDATED"
  fi
  if [ -n "$UNCHECKABLE" ]; then
    echo "Not checkable:"
    echo "$UNCHECKABLE"
  fi
} | tee -a "$GITHUB_STEP_SUMMARY"
