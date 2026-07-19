#!/bin/bash
# brew readall (blocking) + brew audit (advisory until pre-existing findings
# are cleared, then flip it back to blocking) over $CHANGED_JSON.
source "$(dirname "$0")/lib.sh"

cbrew "readall $TAP"

FAIL=()
for name in $(jq -r '.[]' <<< "$CHANGED_JSON"); do
  echo "== brew audit $name =="
  cbrew "audit --formula $TAP/$name" || FAIL+=("$name")
done
if [ "${#FAIL[@]}" -gt 0 ]; then
  echo "::warning::brew audit failed (non-blocking): ${FAIL[*]}"
  echo "- ⚠️ audit failed: ${FAIL[*]}" >> "$GITHUB_STEP_SUMMARY"
fi
