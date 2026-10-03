#!/bin/bash
# For every genuinely new formula in this PR (didn't exist at $BASE), fetch
# the same-named formula from Homebrew/homebrew-core via the GitHub contents
# API and post a diff as a PR comment, so reviewers see exactly what OHOS
# delta we carry over the official Homebrew formula — adapted from
# Harmonybrew/ci's _fetch_upstream_formula_diff. The upstream `bottle do`
# block is stripped before diffing (ours is built by CI, never hand-written).
# Informational only: never fails the job, never gates ci-passed.
set -uo pipefail

CONTENTS_API="https://api.github.com/repos/Homebrew/homebrew-core/contents"

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
  resp=$(curl -s -m 15 -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json" "$CONTENTS_API/$path")

  if ! jq -e '.content' <<< "$resp" > /dev/null 2>&1; then
    BODY+=$'\n\n'"### \`$name\` — 自研 formula（Homebrew/homebrew-core 不存在同名 formula）"
    continue
  fi

  jq -r '.content' <<< "$resp" | base64 -d 2>/dev/null | sed '/^  bottle do$/,/^  end$/d' > "$TMPFILE"

  if diff -q "$TMPFILE" "$path" > /dev/null 2>&1; then
    BODY+=$'\n\n'"### \`$name\` — 与 Homebrew/homebrew-core 除 bottle 块外完全相同（原样搬运）"
  else
    DIFF=$(diff -u --label "homebrew-core/$name.rb" --label "pr/$name.rb" "$TMPFILE" "$path" || true)
    BODY+=$'\n\n'"### \`$name\` — 与 Homebrew/homebrew-core 的差异（已去掉上游 bottle 块）"$'\n\n''```diff'$'\n'"$DIFF"$'\n''```'
  fi
done

if [ "$NEW_COUNT" -eq 0 ]; then
  echo "no new formulae in this PR, nothing to comment"
  exit 0
fi

COMMENT="## 🆕 新 formula 与 Homebrew/homebrew-core 对比$BODY"
gh pr comment "$PR" --repo "$REPO" --body "$COMMENT" \
  || echo "::warning::failed to post upstream-diff comment (non-fatal)"
