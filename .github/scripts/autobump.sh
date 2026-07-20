#!/bin/bash
# Open a bump-formula-pr for each $ALLOWLIST formula with a newer upstream
# livecheck version (optionally narrowed to $ONLY_FORMULA). bump-formula-pr
# itself detects an already-open PR for the same bump and exits non-zero
# without opening a duplicate — treated here as a skip, not a job failure.
source "$(dirname "$0")/lib.sh"

: "${ALLOWLIST:?ALLOWLIST env var required (space-separated formula names)}"
: "${BOT_PUSH_TOKEN:?BOT_PUSH_TOKEN env var required}"

JSON=$(cbrew "livecheck --tap $TAP --json --newer-only") \
  || { echo "::error::brew livecheck failed"; exit 1; }

mapfile -t CANDIDATES < <(
  jq -r --arg allow "$ALLOWLIST" --arg only "${ONLY_FORMULA:-}" '
    ($allow | split(" ")) as $allow
    | .[] | select(.version.latest != null)
    | select(.formula as $f | $allow | index($f))
    | select($only == "" or .formula == $only)
    | "\(.formula)\t\(.version.latest)"
  ' <<< "$JSON"
)

echo "### autobump" >> "$GITHUB_STEP_SUMMARY"

if [ "${#CANDIDATES[@]}" -eq 0 ]; then
  echo "No allowlisted formula has a newer upstream version." >> "$GITHUB_STEP_SUMMARY"
  exit 0
fi

for line in "${CANDIDATES[@]}"; do
  FORMULA=$(cut -f1 <<< "$line")
  LATEST=$(cut -f2 <<< "$line")
  echo "== $FORMULA -> $LATEST =="

  set +e
  OUT=$(docker exec -e HOMEBREW_GITHUB_API_TOKEN="$BOT_PUSH_TOKEN" "$CONTAINER" bash -lc \
    "$BREW_ENV brew bump-formula-pr --no-audit --no-browse --no-fork --version=$LATEST $TAP/$FORMULA" 2>&1)
  STATUS=$?
  set -e
  echo "$OUT"

  PR_URL=$(grep -oE 'https://github\.com/[^ ]+/pull/[0-9]+' <<< "$OUT" | tail -1 || true)
  if [ -n "$PR_URL" ]; then
    PR_NUM="${PR_URL##*/}"
    gh pr edit "$PR_NUM" --add-label bump-formula-pr --repo social4hyq/homebrew-core
    echo "- ✅ $FORMULA $LATEST: $PR_URL" >> "$GITHUB_STEP_SUMMARY"
  elif [ "$STATUS" -ne 0 ]; then
    echo "::warning::$FORMULA bump-formula-pr exited $STATUS with no PR URL (likely a duplicate PR or a bump-formula-pr error, see log above)"
    echo "- ⚠️ $FORMULA $LATEST: no PR opened, see job log" >> "$GITHUB_STEP_SUMMARY"
  else
    echo "::warning::$FORMULA bump-formula-pr exited 0 but no PR URL found in output"
    echo "- ⚠️ $FORMULA $LATEST: exited 0 but no PR URL parsed, check job log" >> "$GITHUB_STEP_SUMMARY"
  fi
done
