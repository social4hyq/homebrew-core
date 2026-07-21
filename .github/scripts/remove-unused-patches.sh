#!/bin/bash
# Find files under Patches/ that no Formula/**/*.rb references by literal
# path (the only way this tap wires up a patch, see any `patch :p1 do / file
# "Patches/..."` block) and open a PR removing them. Never deletes directly
# on main — same "bot pushes a branch, gh pr create" shape as autobump.sh,
# including using GITHUB_TOKEN (github-actions[bot]) rather than a personal
# PAT — this only pushes a fresh non-main branch and opens/labels a PR
# against it, neither of which needs the ruleset-bypass admin PAT that
# pushing bottle commits directly to main requires.
set -euo pipefail

UNUSED=()
while IFS= read -r -d '' patch; do
  rel="${patch#./}"
  if ! grep -rqF "$rel" Formula/ 2>/dev/null; then
    UNUSED+=("$rel")
  fi
done < <(find Patches -type f -print0 | sort -z)

echo "### remove-unused-patches" >> "$GITHUB_STEP_SUMMARY"

if [ "${#UNUSED[@]}" -eq 0 ]; then
  echo "no unused patches found" >> "$GITHUB_STEP_SUMMARY"
  exit 0
fi

echo "unused patch(es): ${#UNUSED[@]}" >> "$GITHUB_STEP_SUMMARY"
for f in "${UNUSED[@]}"; do
  echo "- \`$f\`" >> "$GITHUB_STEP_SUMMARY"
done

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

# Stable branch name (not per-run, unlike RUN_ID) so a later run with the
# same or a shrunk/grown finding set updates the existing PR instead of
# piling up a new one every week — mirrors autobump.sh's deterministic
# branch-name-as-dedup-key approach, but force-pushed since the content
# (not just "does a branch exist") can legitimately change run to run.
BRANCH="remove-unused-patches"
git checkout -B "$BRANCH"
git rm -q "${UNUSED[@]}"

# Clean up any patch directory left empty by the removal above
for f in "${UNUSED[@]}"; do
  dir=$(dirname "$f")
  [ -d "$dir" ] && [ -z "$(ls -A "$dir")" ] && git rm -rq --ignore-unmatch "$dir" 2>/dev/null || true
done

git commit -q -m "chore: remove unused patch(es)

$(printf '%s\n' "${UNUSED[@]}" | sed 's/^/- /')"

git push -qf "https://x-access-token:${GITHUB_TOKEN}@github.com/social4hyq/homebrew-core.git" "$BRANCH" \
  || { echo "::error::failed to push $BRANCH"; exit 1; }

EXISTING=$(gh pr list --repo social4hyq/homebrew-core --head "$BRANCH" --state open --json url --jq '.[0].url // empty')
if [ -n "$EXISTING" ]; then
  echo "PR already open: $EXISTING" >> "$GITHUB_STEP_SUMMARY"
  exit 0
fi

PR_URL=$(gh pr create --repo social4hyq/homebrew-core \
  --head "$BRANCH" --base main \
  --title "chore: remove unused patch(es)" \
  --body "Automated by \`remove-unused-patches.yml\`. Found ${#UNUSED[@]} file(s) under \`Patches/\` that no formula in \`Formula/\` references by path:

$(printf '%s\n' "${UNUSED[@]}" | sed 's/^/- `/;s/$/`/')

Review before merging — a patch can be legitimately unreferenced for a moment mid-migration; this only checks the literal \`Patches/...\` string match, not formula logic.") \
  || { echo "::error::gh pr create failed after a successful push"; exit 1; }

echo "opened $PR_URL" >> "$GITHUB_STEP_SUMMARY"
