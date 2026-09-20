#!/bin/bash
# Post a single upfront "🚪 门禁检查报告" PR comment, adapted from
# Harmonybrew/homebrew-core's HarmonybrewBot (see
# atomgit.com/Harmonybrew/homebrew-core/pull/18194): commit count, formula
# count, commit-message format, surfaced as one readable table before the
# expensive build runs, instead of contributors having to dig into job
# summaries/logs to find out why a PR is stuck.
#
# Deliberately NOT a byte-for-byte port: HarmonybrewBot marks commit-count
# and formula-count ✅/❌ because their upstream enforces one-formula-one-
# commit-per-PR. This tap explicitly does not (see lint-commit-messages.sh's
# header) — multi-formula, multi-commit PRs are normal here — so those two
# rows are informational (ℹ️) only. Commit-message format is the one row
# that mirrors lint-commits' actual pass/fail, since that check IS enforced
# here.
#
# Comment-only: never gates ci-passed itself (label job keys off the real
# job results, not this comment).
set -uo pipefail

BOT_RE='^[^[:space:]]+: (add|update) .+ bottle\.$'
NEW_FORMULA_RE='^[^[:space:]]+ [^[:space:]]+ \(new formula\)$'
REVISION_RE='^[^[:space:]]+: revision bump to .+$'
FIX_RE='^[^[:space:]]+: .+$'
BUMP_RE='^[^[:space:]]+ [^[:space:]]+$'

COMMIT_COUNT=0
BAD_MSG=""
while IFS= read -r sha; do
  git diff-tree --no-commit-id --name-only -r "$sha" -- 'Formula/' | grep -q . || continue
  msg=$(git log -1 --format=%s "$sha")
  [[ "$msg" =~ $BOT_RE ]] && continue
  COMMIT_COUNT=$((COMMIT_COUNT + 1))
  if [[ -z "$BAD_MSG" ]] \
     && ! [[ "$msg" =~ $NEW_FORMULA_RE || "$msg" =~ $REVISION_RE || "$msg" =~ $FIX_RE || "$msg" =~ $BUMP_RE ]]; then
    BAD_MSG="$msg"
  fi
done < <(git log --format=%H --no-merges "$BASE..$HEAD")

FORMULA_NAMES=$(jq -r 'join(", ")' <<< "$CHANGED_JSON")
FORMULA_COUNT=$(jq -r 'length' <<< "$CHANGED_JSON")

if [[ "$LINT_RESULT" == "success" ]]; then
  MSG_MARK="✅"
  MSG_DETAIL="格式正确"
  VERDICT="门禁检查通过，构建正常进行。"
else
  MSG_MARK="❌"
  if [[ -n "$BAD_MSG" ]]; then
    MSG_DETAIL="不符合规范：\`$BAD_MSG\`"
  else
    MSG_DETAIL="见 lint-commits job 日志"
  fi
  VERDICT="commit message 未通过检查，构建已跳过。"
fi

COMMENT=$(cat <<EOF
## 🚪 门禁检查报告

> $VERDICT

| 检查项 | 结果 | 详情 |
|--------|------|------|
| Commit 数量 | ℹ️ | $COMMIT_COUNT 个 commit |
| Formula 数量 | ℹ️ | $FORMULA_COUNT 个 formula ($FORMULA_NAMES) |
| Commit Message 格式 | $MSG_MARK | $MSG_DETAIL |
EOF
)

gh pr comment "$PR" --repo "$REPO" --body "$COMMENT" \
  || echo "::warning::failed to post gate-check comment (non-fatal)"
