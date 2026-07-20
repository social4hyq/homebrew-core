#!/bin/bash
# For every genuinely new formula in this PR (didn't exist at $BASE), fetch
# the same-named formula from Harmonybrew/homebrew-core (our stated
# migration target — see README's "稳定后合入上游") via the atomgit
# contents API and post a diff as a PR comment — adapted from
# Harmonybrew/ci's _fetch_upstream_formula_diff (which compares against the
# official Homebrew/homebrew-core; we compare against our actual upstream
# instead). Informational only: never fails the job, never gates ci-passed.
set -uo pipefail

CONTENTS_API="https://atomgit.com/api/v5/repos/Harmonybrew/homebrew-core/contents"

subdir_for() {
  local name="${1,,}"
  if [[ "$name" == lib* ]]; then
    echo "lib"
  else
    echo "${name:0:1}"
  fi
}

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

BODY=""
NEW_COUNT=0

for name in $(jq -r '.[]' <<< "$CHANGED_JSON"); do
  subdir=$(subdir_for "$name")
  path="Formula/$subdir/$name.rb"

  # only comment on formulae that didn't exist before this PR
  git cat-file -e "$BASE:$path" 2>/dev/null && continue

  NEW_COUNT=$((NEW_COUNT + 1))
  resp=$(curl -s -m 15 "$CONTENTS_API/$path")

  if ! jq -e '.content' <<< "$resp" > /dev/null 2>&1; then
    BODY+=$'\n\n'"### \`$name\` — 自研 formula（Harmonybrew/homebrew-core 不存在同名 formula）"
    continue
  fi

  jq -r '.content' <<< "$resp" | base64 -d > "$TMPFILE" 2>/dev/null

  if diff -q "$TMPFILE" "$path" > /dev/null 2>&1; then
    BODY+=$'\n\n'"### \`$name\` — 与 Harmonybrew/homebrew-core 完全相同（原样搬运）"
  else
    DIFF=$(diff -u --label "harmonybrew-core/$name.rb" --label "pr/$name.rb" "$TMPFILE" "$path" || true)
    BODY+=$'\n\n'"### \`$name\` — 与 Harmonybrew/homebrew-core 的差异"$'\n\n''```diff'$'\n'"$DIFF"$'\n''```'
  fi
done

if [ "$NEW_COUNT" -eq 0 ]; then
  echo "no new formulae in this PR, nothing to comment"
  exit 0
fi

COMMENT="## 🆕 新 formula 与 Harmonybrew/homebrew-core 对比$BODY"
gh pr comment "$PR" --repo "$REPO" --body "$COMMENT" \
  || echo "::warning::failed to post upstream-diff comment (non-fatal)"
