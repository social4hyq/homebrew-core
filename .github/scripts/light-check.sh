#!/bin/bash
# brew readall + brew audit (both blocking) over $CHANGED_JSON.
source "$(dirname "$0")/lib.sh"

cbrew "readall $TAP"

FAIL=()
for name in $(jq -r '.[]' <<< "$CHANGED_JSON"); do
  echo "== brew audit $name =="
  cbrew "audit --formula $TAP/$name" || FAIL+=("$name")
done
if [ "${#FAIL[@]}" -gt 0 ]; then
  echo "::error::brew audit failed: ${FAIL[*]}"
  echo "- ❌ audit failed: ${FAIL[*]}" >> "$GITHUB_STEP_SUMMARY"
  exit 1
fi
