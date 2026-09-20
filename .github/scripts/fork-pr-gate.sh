#!/bin/bash
# Fork PR gate + replacement PR (idea adapted from Harmonybrew/ci's
# auto_bottle.py validate_pr/create_replacement_pr).
#
# A plain `pull_request` from a fork gets a read-only token and no secrets —
# pr-validate.yml can't comment, label, or build for it. This script runs
# under `pull_request_target` instead (base-repo permissions regardless of
# PR source) to give external contributors fast feedback and, if the PR
# passes lightweight metadata checks, copy its content onto a same-repo
# branch so it flows through the normal pr-validate.yml pipeline.
#
# SECURITY: pull_request_target must never check out AND EXECUTE fork code
# with these elevated permissions. Every operation below is either pure git
# metadata inspection (log/diff/diff-tree — reads history, runs nothing) or
# a content copy (fetch + push, no execution). No script from the fork is
# ever invoked. The actual build/test of the copied content happens later,
# safely, in the replacement PR's normal same-repo pull_request run.
set -euo pipefail

: "${PR_NUM:?}"
: "${BOT_PUSH_TOKEN:?}"
REPO="social4hyq/homebrew-core"
export GH_TOKEN="$BOT_PUSH_TOKEN"

LABELS=$(gh pr view "$PR_NUM" --repo "$REPO" --json labels --jq '.labels[].name')
if grep -qx "replaced" <<< "$LABELS"; then
  echo "PR #$PR_NUM already has a replacement, skipping."
  exit 0
fi

# Explicit authenticated URL for both fetch and push, rather than the
# ambient `origin` remote actions/checkout sets up: mixing an embedded-PAT
# URL with actions/checkout's own short-lived http.extraheader credential
# caused a 403/conflict once already this session (setup-container.sh's
# bump-formula-pr fix) — sidestep the whole class of bug by never touching
# `origin` here.
AUTH_URL="https://social4hyq:${BOT_PUSH_TOKEN}@github.com/$REPO.git"
git fetch "$AUTH_URL" "pull/$PR_NUM/head:pr-$PR_NUM-head" "main:gate-base-main"
BASE="gate-base-main"
HEAD="pr-$PR_NUM-head"
MERGE_BASE=$(git merge-base "$BASE" "$HEAD")

CHECKS=()
PASS=1

# --- check 1: commit count ---
N=$(git rev-list --count "$MERGE_BASE..$HEAD")
if [ "$N" -eq 1 ]; then
  CHECKS+=("| Commit 数量 | ✅ | 1 个 commit |")
else
  CHECKS+=("| Commit 数量 | ❌ | 包含 $N 个 commit，只允许 1 个 |")
  PASS=0
fi

# --- check 2: exactly one formula touched ---
mapfile -t FORMULA_FILES < <(git diff --name-only "$MERGE_BASE..$HEAD" -- 'Formula/*/*.rb')
FCOUNT="${#FORMULA_FILES[@]}"
FORMULA_NAME=""
if [ "$FCOUNT" -eq 1 ]; then
  FORMULA_NAME="$(basename "${FORMULA_FILES[0]}" .rb)"
  CHECKS+=("| Formula 数量 | ✅ | 1 个 formula ($FORMULA_NAME) |")
elif [ "$FCOUNT" -eq 0 ]; then
  CHECKS+=("| Formula 数量 | ❌ | 未修改任何 formula |")
  PASS=0
else
  CHECKS+=("| Formula 数量 | ❌ | 包含 $FCOUNT 个 formula，只允许 1 个（每个 PR 只改一个 formula） |")
  PASS=0
fi

# --- check 3: commit message format (same convention as lint-commit-messages.sh) ---
MSG=$(git log -1 --format=%s "$HEAD")
NEW_FORMULA_RE='^[^[:space:]]+ [^[:space:]]+ \(new formula\)$'
REVISION_RE='^[^[:space:]]+: revision bump to .+$'
FIX_RE='^[^[:space:]]+: .+$'
BUMP_RE='^[^[:space:]]+ [^[:space:]]+$'
if [[ "$MSG" =~ $NEW_FORMULA_RE ]]; then
  CHECKS+=("| Commit Message 格式 | ✅ | 新增 formula：\`$MSG\` |")
elif [[ "$MSG" =~ $REVISION_RE ]]; then
  CHECKS+=("| Commit Message 格式 | ✅ | 修订版本升级：\`$MSG\` |")
elif [[ "$MSG" =~ $FIX_RE ]]; then
  CHECKS+=("| Commit Message 格式 | ✅ | 修复/增强：\`$MSG\` |")
elif [[ "$MSG" =~ $BUMP_RE ]]; then
  CHECKS+=("| Commit Message 格式 | ✅ | 版本升级：\`$MSG\` |")
else
  CHECKS+=("| Commit Message 格式 | ❌ | 不符合规范：\`$MSG\` |")
  PASS=0
fi

# --- report ---
REPORT="## 🚪 门禁检查报告
"
if [ "$PASS" -eq 1 ]; then
  REPORT+="
> 门禁检查全部通过，即将生成替代 PR。
"
else
  REPORT+="
> 门禁检查未通过，不会生成替代 PR。请整改后关闭本 PR 重新提交（新 PR 会立即重新触发门禁，无需等待人工处理）。
"
fi
REPORT+="
| 检查项 | 结果 | 详情 |
|---|---|---|
$(printf '%s\n' "${CHECKS[@]}")"

gh pr comment "$PR_NUM" --repo "$REPO" --body "$REPORT"

if [ "$PASS" -ne 1 ]; then
  exit 0
fi

# --- replacement PR: copy content onto a same-repo branch, no execution ---
BRANCH="replace-$PR_NUM"
git push "$AUTH_URL" "$HEAD:refs/heads/$BRANCH"

TITLE=$(gh pr view "$PR_NUM" --repo "$REPO" --json title --jq .title)
PR_BODY="[#$PR_NUM](https://github.com/$REPO/pull/$PR_NUM) 的替代 PR，门禁检查通过后由机器人自动创建（原 PR 来自 fork，没有直接触发 CI 构建的写权限）。"
PR_URL=$(gh pr create --repo "$REPO" --head "$BRANCH" --base main \
  --title "$TITLE (replacement for #$PR_NUM)" --body "$PR_BODY")

gh pr comment "$PR_NUM" --repo "$REPO" --body "机器人不具备 PR 源分支的写权限，已生成替代 PR $PR_URL 进行处理，后续 CI/合并请在那边跟进。"
gh pr edit "$PR_NUM" --repo "$REPO" --add-label replaced
echo "Created replacement PR: $PR_URL"
