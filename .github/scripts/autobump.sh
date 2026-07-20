#!/bin/bash
# Open a bump-formula-pr for each $ALLOWLIST formula with a newer upstream
# livecheck version (optionally narrowed to $ONLY_FORMULA).
#
# `brew bump-formula-pr` does the valuable part (resolve the new version,
# fetch the release to compute its checksum, edit the formula, commit, push
# the branch) but its own "open the PR" step is hardcoded to AtomGit's API
# regardless of the tap's actual remote (confirmed 2026-07-20 — this is
# Harmonybrew's own upstream fork, built for their AtomGit-hosted tap; ours
# lives on GitHub, AtomGit is just a mirror). So it always "fails" at that
# last step even on a fully successful run — expected, not an error. The
# branch it already pushed to GitHub is what we actually care about; this
# script opens the real GitHub PR itself once that branch exists.
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

# setup-container.sh drops actions/checkout's ephemeral extraheader (it
# authenticates as github-actions[bot], which can't push here — 403), but
# bump-formula-pr's own `git push` doesn't inject HOMEBREW_GITHUB_API_TOKEN
# into git's credentials itself; without a replacement it fails outright
# ("could not read Username", confirmed 2026-07-20). Rewrite every
# https://github.com/ URL to embed BOT_PUSH_TOKEN so any git push bump-
# formula-pr constructs picks it up transparently, regardless of the exact
# URL shape it builds.
docker exec "$CONTAINER" bash -lc \
  "git config --global url.\"https://social4hyq:${BOT_PUSH_TOKEN}@github.com/\".insteadOf \"https://github.com/\""

for line in "${CANDIDATES[@]}"; do
  FORMULA=$(cut -f1 <<< "$line")
  LATEST=$(cut -f2 <<< "$line")
  echo "== $FORMULA -> $LATEST =="

  set +e
  # timeout guard: a hang here (e.g. a future git-config regression) should
  # fail this one formula fast, not silently burn the whole job's 30min
  # budget (happened during 2026-07-20 debugging of the remote-repository
  # issue this script used to hit)
  OUT=$(timeout 300 docker exec -e HOMEBREW_GITHUB_API_TOKEN="$BOT_PUSH_TOKEN" "$CONTAINER" bash -lc \
    "$BREW_ENV brew bump-formula-pr --no-audit --no-browse --no-fork --version=$LATEST $TAP/$FORMULA" 2>&1)
  STATUS=$?
  set -e
  [ "$STATUS" -eq 124 ] && echo "::warning::$FORMULA bump-formula-pr TIMED OUT after 300s"
  echo "$OUT"

  # Deterministic branch name bump-formula-pr uses internally
  # (Homebrew::Bump::BumpInfo#branch_name: "bump-#{formula}-#{version}").
  BRANCH="bump-${FORMULA}-${LATEST}"

  if ! git ls-remote --exit-code --heads \
       "https://social4hyq:${BOT_PUSH_TOKEN}@github.com/social4hyq/homebrew-core.git" "$BRANCH" \
       > /dev/null 2>&1; then
    echo "::warning::$FORMULA bump-formula-pr didn't push $BRANCH — a real failure (audit/fetch/checksum), see log above"
    echo "- ⚠️ $FORMULA $LATEST: no branch pushed, see job log" >> "$GITHUB_STEP_SUMMARY"
    continue
  fi

  EXISTING=$(gh pr list --repo social4hyq/homebrew-core --head "$BRANCH" --state open --json url --jq '.[0].url // empty')
  if [ -n "$EXISTING" ]; then
    echo "- ⏭️ $FORMULA $LATEST: PR already open: $EXISTING" >> "$GITHUB_STEP_SUMMARY"
    continue
  fi

  PR_URL=$(gh pr create --repo social4hyq/homebrew-core \
    --head "$BRANCH" --base main \
    --title "$FORMULA $LATEST" \
    --body "Automated version bump via \`brew bump-formula-pr\` (autobump.yml, formula edit/checksum computed by brew; PR opened here since bump-formula-pr's own PR step is AtomGit-only in this Homebrew fork).") \
    || { echo "::error::$FORMULA: gh pr create failed after a successful push"; echo "- ❌ $FORMULA $LATEST: push OK, gh pr create failed" >> "$GITHUB_STEP_SUMMARY"; continue; }

  PR_NUM="${PR_URL##*/}"
  gh pr edit "$PR_NUM" --repo social4hyq/homebrew-core --add-label bump-formula-pr
  echo "- ✅ $FORMULA $LATEST: $PR_URL" >> "$GITHUB_STEP_SUMMARY"
done
