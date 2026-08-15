#!/bin/bash
# Upload the bottle to the atomgit release $TAG, merge the bottle block back
# into the formula, and push to $PUSH_REF (default main; a PR's own head
# branch when called from pr-validate.yml — see bottle-build.yml).
source "$(dirname "$0")/lib.sh"

: "${PUSH_REF:=main}"
: "${REASON:=}"

API=https://atomgit.com/api/v5/repos/social4hyq/homebrew-core
ag() { curl -sf -m 30 --retry 3 --retry-delay 5 --retry-connrefused -H "Authorization: Bearer $ATOMGIT_TOKEN" "$@"; }

BOTTLE=$(ls bottle-out/*.tar.gz | head -1)
FILENAME=$(basename "$BOTTLE")

# 1. get-or-create release (atomgit returns no release id; keyed by tag)
# TODO(M3): a flaky GET falls through to POST and hits a confusing 409
# target_commitish is always "main", never $PUSH_REF: atomgit only mirrors
# GitHub main (sync-to-atomgit.yml), so a PR branch that hasn't merged yet
# doesn't exist as a ref on atomgit at all — pointing target_commitish at it
# 400s with "<branch> is not exist" (confirmed 2026-07-20). The release/tag
# only hosts the uploaded bottle asset (addressed by root_url); it doesn't
# need to correspond to a real commit on atomgit's side.
BODY="$TAG bottle (CI run $RUN_NUMBER)"
[ -n "$REASON" ] && BODY="$BODY — $REASON"
ag "$API/releases/tags/$TAG" \
  || ag -X POST -H "Content-Type: application/json" \
       -d "$(jq -n --arg tag "$TAG" --arg body "$BODY" \
             '{tag_name: $tag, name: $tag, target_commitish: "main", body: $body}')" \
       "$API/releases"

# 2. tune TCP for the trans-Pacific OBS upload. CUBIC's loss-based window
#    never fills this long-fat path — obs-upload-tune (run 29714217969,
#    2026-07-20) caught a slow window and measured 45.85 KB/s on unmodified
#    CUBIC vs 4577 KB/s with BBR + fq pacing + larger send/receive buffers +
#    a bumped initial congestion window (~100x). Best-effort: a runner
#    without CAP_NET_ADMIN just keeps CUBIC and the PUT below still runs,
#    only slower. Deliberately does NOT touch the live interface's qdisc
#    (tc qdisc replace broke DNS resolution outright on 3 of 4 probe runs —
#    see obs-upload-tune history) — BBR's in-kernel pacing fallback works
#    without it.
sudo modprobe tcp_bbr 2>/dev/null || true
sudo sysctl -q -w net.core.default_qdisc=fq net.ipv4.tcp_congestion_control=bbr \
  net.core.wmem_max=134217728 net.core.rmem_max=134217728 \
  net.ipv4.tcp_wmem='4096 262144 134217728' net.ipv4.tcp_rmem='4096 262144 134217728' 2>/dev/null || true
DEFROUTE=$(ip route show default 2>/dev/null)
[ -n "$DEFROUTE" ] && { sudo ip route change $DEFROUTE initcwnd 64 initrwnd 64 2>/dev/null || true; }

# 3. presigned upload URL (file_name required), then PUT to OBS object storage.
#    GHA-to-OBS bandwidth can sink to ~15-18KB/s on a bad trans-Pacific
#    window (measured 2026-07-19/20) even with the tuning above applied
#    (e.g. no CAP_NET_ADMIN), so a hard -m 300 kills viable-but-slow
#    uploads. Use low-speed detection instead: <1KB/s sustained for 120s =
#    genuinely stalled; -m 7200 caps a 71MB llvm-sized bottle even at the
#    observed worst-case rate. --tcp-nodelay + empty Expect: header were
#    part of the validated fast configuration, keep them alongside the
#    sysctl tuning above.
RESP=$(ag "$API/releases/$TAG/upload_url?file_name=$FILENAME")
curl -sf --tcp-nodelay -H "Expect:" --speed-limit 1024 --speed-time 120 -m 7200 -X PUT "$(echo "$RESP" | jq -r .url)" \
  -H "x-obs-meta-project-id: $(echo "$RESP" | jq -r '.headers["x-obs-meta-project-id"]')" \
  -H "x-obs-acl: $(echo "$RESP" | jq -r '.headers["x-obs-acl"]')" \
  -H "x-obs-callback: $(echo "$RESP" | jq -r '.headers["x-obs-callback"]')" \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@$BOTTLE" -w "HTTP=%{http_code}\n"

# 4. merge bottle block back (--merge takes the json file, not the formula name)
docker exec -w "$TAP_IN_CONTAINER/bottle-out" "$CONTAINER" bash -lc \
  "$BREW_ENV brew bottle --merge --write ./*.bottle.json"
# brew committed as root in-container; restore ownership before git push
sudo chown -R "$(id -u):$(id -g)" "$GITHUB_WORKSPACE"

# 5. Land the bottle commit. Two paths share one push helper:
#    - $PUSH_REF is a PR branch (pr-validate.yml workflow_call): push directly
#      to that branch; the PR's own merge carries it into main.
#    - $PUSH_REF is main (manual bottle-build.yml dispatch): the protect-main
#      ruleset requires the `label` status check, which only a PR merge can
#      satisfy — no token bypasses required-status-checks for a direct push
#      (verified 2026-08-13: 5 manual dispatches all built+uploaded fine but
#      were rejected at push with "Required status check 'label' is expected").
#      So push to a bot branch and open + merge a PR. HEAD is a bottle
#      write-back commit ("<formula>: update ... bottle." from `brew bottle
#      --merge --write`), and detect-changes.sh skips the rebuild for exactly
#      that commit shape — verified 2026-08-13: such a PR reaches ci-passed in
#      ~10s with build/light-check/upstream-diff all skipped, no redundant CI.
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add Formula/
# `brew bottle --merge --write` above already committed with the standard
# "<formula>: update <ver> bottle." message; this fallback only fires if it
# didn't, and is kept BOTTLE_COMMIT_RE-shaped so a resulting bot PR is still
# treated as a write-back (detect skips the rebuild).
COMMIT_MSG="${FORMULA}: update ${TAG} bottle."
git diff --cached --quiet || git commit -m "$COMMIT_MSG"

git config --unset-all http.https://github.com/.extraheader || true
GH_PUSH_URL="https://social4hyq:${BOT_PUSH_TOKEN}@github.com/social4hyq/homebrew-core.git"

# Push HEAD to $1, fetch+rebase retrying on non-fast-forward (concurrent
# per-formula publishes can race). The retry is strict by design:
#   - never carry a half-done rebase into the next attempt (rebase --abort);
#   - never merge in a remote tip that does not descend from our checkout
#     base (a force-pushed / polluted branch would otherwise get replayed
#     onto the PR — 2026-08-15: a stale-branch build matrix pushed foreign
#     deepseek-harness commits onto rebump-opencode2 this way);
#   - a content conflict (two jobs editing the same file) is a human problem:
#     abort loudly instead of pushing a conflicted state;
#   - after a clean rebase, HEAD must be exactly FETCH_HEAD + our own single
#     bottle commit — anything else means foreign commits were replayed.
# A real failure leaves the atomgit release uploaded but the branch untouched,
# with an actionable error instead of a corrupted PR branch.
push_bottle_commit() {  # $1 = destination ref (HEAD:$1)
  # The bottle write-back is a single commit on the checkout base
  # (pull_request.head.sha for PR runs; the pre-push HEAD for manual
  # dispatches). Remember both before any retry mutates local state.
  base_sha=$(git rev-parse "HEAD^" 2>/dev/null || git rev-parse HEAD)
  for i in 1 2 3; do
    if git push "$GH_PUSH_URL" "HEAD:$1" 2>/dev/null; then return 0; fi
    [ "$i" = 3 ] && { echo "::error::push to $1 failed 3 times; atomgit release $TAG already uploaded, verify the bottle merge manually"; exit 1; }
    echo "::warning::push to $1 rejected (concurrent update?), fetch+rebase retry ($i/3)"
    # Clear any leftover rebase state from a previous failed attempt.
    git rebase --abort 2>/dev/null || true
    git fetch origin "$1" 2>/dev/null || {
      echo "::error::fetch of origin/$1 failed; release $TAG already uploaded, verify the bottle merge manually"; exit 1; }
    # The remote tip must descend from OUR base; otherwise the branch was
    # rewritten under us (force-push/pollution) and rebasing would replay
    # foreign commits onto it.
    if ! git merge-base --is-ancestor "$base_sha" "FETCH_HEAD"; then
      echo "::error::remote $1 does not descend from $(git rev-parse --short "$base_sha") (force-pushed or polluted?); release $TAG already uploaded, merge manually"
      exit 1
    fi
    if ! git rebase "FETCH_HEAD"; then
      git rebase --abort
      echo "::error::rebase onto $1 conflicted (concurrent edit of the same file?); release $TAG already uploaded, merge manually"
      exit 1
    fi
    # Sanity: only our own bottle commit may sit on top of the remote tip.
    if [ "$(git rev-list --count "FETCH_HEAD..HEAD")" != "1" ]; then
      echo "::error::rebase produced $(git rev-list --count "FETCH_HEAD..HEAD") commits on top of origin/$1 (expected 1); release $TAG already uploaded, merge manually"
      exit 1
    fi
    sleep 5
  done
}

if [ "$PUSH_REF" = "main" ]; then
  BOT_BRANCH="bot/bottle/${FORMULA}/run-${RUN_NUMBER}"
  push_bottle_commit "$BOT_BRANCH"
  # Use BOT_PUSH_TOKEN (admin PAT) — not GITHUB_TOKEN — for pr create/view/merge:
  # the workflow GITHUB_TOKEN lacks pull-requests:write AND its events don't
  # trigger downstream workflows (GitHub anti-recursion), so pr-validate would
  # never run and ci-passed would never land. A PAT both has the scope and its
  # events trigger pr-validate on the bot PR.
  if ! PR_URL="$(GH_TOKEN="$BOT_PUSH_TOKEN" gh pr create --base main --head "$BOT_BRANCH" --repo social4hyq/homebrew-core \
        --title "${FORMULA}: rebuild bottle ${TAG}" \
        --body "Auto-generated by bottle-build.yml manual dispatch (run ${RUN_NUMBER}). HEAD is a bottle write-back commit, so pr-validate skips the rebuild and runs only lint-commits + label. Auto-merges once ci-passed.")"; then
    echo "::error::gh pr create for $BOT_BRANCH failed; atomgit release $TAG uploaded, open the PR manually"
    exit 1
  fi
  PR_NUM="$(basename "$PR_URL")"
  echo "::notice::opened bottle PR #$PR_NUM ($PR_URL); waiting for ci-passed"
  # A bottle-writeback PR reaches ci-passed in ~10-60s; poll up to ~5min.
  for i in $(seq 1 30); do
    if GH_TOKEN="$BOT_PUSH_TOKEN" gh pr view "$PR_NUM" --repo social4hyq/homebrew-core --json labels -q '[.labels[].name]' 2>/dev/null | grep -q '"ci-passed"'; then
      break
    fi
    sleep 10
  done
  if ! GH_TOKEN="$BOT_PUSH_TOKEN" gh pr merge "$PR_NUM" --merge --admin --delete-branch --repo social4hyq/homebrew-core; then
    echo "::error::bottle PR #$PR_NUM did not reach ci-passed/merge within ~5min; atomgit release $TAG uploaded, merge manually: $PR_URL"
    exit 1
  fi
  echo "::notice::bottle PR #$PR_NUM merged to main"
else
  # PR-branch path (pr-validate workflow_call) — direct push, unchanged.
  push_bottle_commit "$PUSH_REF"
fi
# atomgit main is kept in sync by sync-to-atomgit.yml on push to GitHub main.
# Neither a PR-branch push nor the bot-branch push above is main, so neither
# triggers that sync directly; atomgit picks the bottle up once the PR merges.

# 6. GitHub release mirror copy, best-effort (atomgit stays the primary:
#    every root_url points there; this is disaster-recovery / future-switch
#    material only, so a failure here never fails the publish and never
#    triggers rollback-release.sh)
#
#    create and upload are checked separately on purpose: only a
#    create-succeeded/upload-failed pair is "this run's own half-made
#    release" and safe to clean up. A create failure (e.g. 422 tag already
#    exists, which happens if atomgit's tag number gets reused after an
#    out-of-band rollback while the old GitHub mirror release is untouched)
#    means this run made nothing — the unconditional cleanup used to run
#    here regardless, and on 2026-07-20 that deleted a perfectly good prior
#    mirror release + tag from an earlier run. Leave existing releases
#    alone when create itself fails.
if gh release create "$TAG" -R social4hyq/homebrew-core \
     --title "$TAG" --notes "$TAG bottle mirror (CI run $RUN_NUMBER); primary: atomgit release $TAG"; then
  if gh release upload "$TAG" -R social4hyq/homebrew-core "$BOTTLE"; then
    echo "github mirror release $TAG done"
  else
    # create succeeded but upload didn't: genuinely this run's half-made release
    gh release delete "$TAG" -R social4hyq/homebrew-core --yes --cleanup-tag 2>/dev/null || true
    echo "::warning::github mirror release $TAG upload failed; atomgit publish is complete, backfill the mirror manually"
    echo "- ⚠️ github mirror $TAG upload failed — backfill manually (atomgit publish OK)" >> "$GITHUB_STEP_SUMMARY"
  fi
else
  echo "::warning::github mirror release $TAG create failed (tag may already exist from an earlier run); atomgit publish is complete, check manually"
  echo "- ⚠️ github mirror $TAG create failed — check manually (atomgit publish OK)" >> "$GITHUB_STEP_SUMMARY"
fi
