#!/bin/bash
# Validate each human commit in $BASE..$HEAD that touches Formula/** against
# the tap's commit message convention (adapted from Harmonybrew/ci's
# _check_commit_message). Commits that don't touch any formula (e.g. a
# workflow-only commit mixed into the same PR — this tap doesn't enforce
# Harmonybrew's strict one-formula-one-commit-per-PR rule) are out of scope
# entirely, not just exempt like bot commits. CI's own bottle write-back
# commits ARE exempt despite touching Formula/** — they're machine-authored
# and already recognized elsewhere (detect-changes.sh) by the same shape.
set -euo pipefail

BOT_RE='^[^[:space:]]+: (add|update) .+ bottle\.$'
NEW_FORMULA_RE='^[^[:space:]]+ [^[:space:]]+ \(new formula\)$'
REVISION_RE='^[^[:space:]]+: revision bump to .+$'
FIX_RE='^[^[:space:]]+: .+$'
BUMP_RE='^[^[:space:]]+ [^[:space:]]+$'

FAIL=0
CHECKED=0
{
  echo "### commit-message lint"
  echo "| commit | message | result |"
  echo "|---|---|---|"
} >> "$GITHUB_STEP_SUMMARY"

while IFS= read -r sha; do
  # skip commits that don't touch any formula at all — out of scope, not
  # subject to the convention (workflow/docs commits mixed into the PR)
  git diff-tree --no-commit-id --name-only -r "$sha" -- 'Formula/' \
    | grep -q . || continue

  msg=$(git log -1 --format=%s "$sha")
  short="${sha:0:7}"

  if [[ "$msg" =~ $BOT_RE ]]; then
    echo "-- $short: bot bottle write-back, skipping — $msg"
    echo "| \`$short\` | \`$msg\` | ⏭️ bot commit |" >> "$GITHUB_STEP_SUMMARY"
    continue
  fi

  CHECKED=$((CHECKED + 1))
  if [[ "$msg" =~ $NEW_FORMULA_RE ]]; then
    kind="new formula"
  elif [[ "$msg" =~ $REVISION_RE ]]; then
    kind="revision bump"
  elif [[ "$msg" =~ $FIX_RE ]]; then
    kind="fix/enhancement"
  elif [[ "$msg" =~ $BUMP_RE ]]; then
    kind="version bump"
  else
    kind=""
  fi

  if [ -n "$kind" ]; then
    echo "-- $short: OK ($kind) — $msg"
    echo "| \`$short\` | \`$msg\` | ✅ $kind |" >> "$GITHUB_STEP_SUMMARY"
  else
    echo "::error::commit $short message does not match convention: \"$msg\""
    echo "| \`$short\` | \`$msg\` | ❌ no match |" >> "$GITHUB_STEP_SUMMARY"
    FAIL=1
  fi
done < <(git log --format=%H --no-merges "$BASE..$HEAD")

if [ "$CHECKED" -eq 0 ]; then
  echo "::warning::no human commits found in $BASE..$HEAD (only bot commits?)"
fi

if [ "$FAIL" -eq 1 ]; then
  cat >> "$GITHUB_STEP_SUMMARY" <<'EOF'

**规范**（首行）：
- 新增 formula：`<formula> <version> (new formula)`
- 版本升级：`<formula> <version>`
- revision 升级：`<formula>: revision bump to <reason>`
- 修复/增强：`<formula>: <action>`
EOF
  echo "::error::one or more commit messages don't match the convention, see job summary"
  exit 1
fi

echo "all commit messages OK" >> "$GITHUB_STEP_SUMMARY"
