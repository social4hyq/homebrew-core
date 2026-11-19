#!/bin/bash
# Upload the bottle to the atomgit release $TAG, merge the bottle block back
# into the formula, and push to $PUSH_REF (default main; a PR's own head
# branch when called from pr-validate.yml — see bottle-build.yml).
source "$(dirname "$0")/lib.sh"

: "${PUSH_REF:=main}"
: "${REASON:=}"

API=https://atomgit.com/api/v5/repos/social4hyq/homebrew-core
ag() { curl -sS --fail-with-body -m 30 --retry 3 --retry-delay 5 --retry-connrefused -H "Authorization: Bearer $ATOMGIT_TOKEN" "$@"; }

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

# 3. presigned upload URL (file_name required), then hedged PUT to OBS.
#    The PUT lands on file.gitcode.com (one A record in front of a Huawei
#    Cloud bucket), so every connection crosses the same long fat path and
#    per-connection throughput is a lottery. 2026-11-19 bench (throwaway
#    workflow runs, 6 uploads per config, same VM and edge IP):
#      - one connection: 43 KiB/s .. 1.3 MiB/s back-to-back (3 of 6 landed
#        above 850 KiB/s, 3 below 130) — that is how a 199 MiB bottle spent
#        29m36s on a single PUT while the same bytes reach GitHub in 8s
#      - 4 concurrent PUTs of the SAME object: the fastest finished a 64 MiB
#        blob in 22.2s (3.03 MiB/s), 26x the single-connection rate, with
#        the stored object byte-identical and exactly one attachment
#      - BBR/initcwnd below is confirmed applied (cc=bbr, sysctls rc=0),
#        x86 runners are no faster, the host speaks HTTP/1.1 only and has no
#        multipart API — concurrency is the only lever that moves this.
#    So race N PUTs of the same bytes and keep the first 2xx. Whole-object
#    PUTs commit only when the body is fully received, so killing the losers
#    cannot corrupt what the winner wrote.
#    Two details came out of the first live attempt (run 44552723437):
#      - duplicate uploads of an object that is already stored answer 203
#        (Non-Authoritative Information), not 200 — accept any 2xx, or a good
#        upload gets reported as a failure;
#      - a per-connection --speed-limit is wrong here: K connections share one
#        thin pipe, so every one of them can sit under the floor and curl
#        aborts the whole hedge. Only the wall-clock deadline applies now, and
#        a connection that dies is simply replaced (up to
#        BOTTLE_UPLOAD_MAX_ATTEMPTS) instead of taking the step down with it.
RESP=$(ag "$API/releases/$TAG/upload_url?file_name=$FILENAME")
UPLOAD_URL=$(echo "$RESP" | jq -r .url)
HDR_META=$(echo "$RESP" | jq -r '.headers["x-obs-meta-project-id"]')
HDR_ACL=$(echo "$RESP" | jq -r '.headers["x-obs-acl"]')
HDR_CB=$(echo "$RESP" | jq -r '.headers["x-obs-callback"]')
SIZE=$(stat -c%s "$BOTTLE")

HEDGE=${BOTTLE_UPLOAD_HEDGE:-4}                  # connections in the first wave
HEDGE_MAX=${BOTTLE_UPLOAD_MAX:-12}               # hard cap on concurrency
HEDGE_ATTEMPTS=${BOTTLE_UPLOAD_MAX_ATTEMPTS:-24} # total connections across replacements
WAVE_DELAY=${BOTTLE_UPLOAD_WAVE_DELAY:-120}      # widen the hedge after this long
UPLOAD_TIMEOUT=${BOTTLE_UPLOAD_TIMEOUT:-7200}    # wall-clock cap, matches the old per-PUT -m
TARGET=$HEDGE
UPLOAD_DIR=$(mktemp -d)
PIDS=()
LAUNCHED=0

# One whole-object PUT. `exec` makes the subshell become curl, so $! is
# curl's own pid and killing it really closes the upload (a killed subshell
# would leave curl orphaned and still writing). `-w` output lands in
# $UPLOAD_DIR/<n>.code as "<http code> <seconds> <bytes> <bytes/s>".
start_wave() { # $1 = how many connections to add
  local n=$1 i
  [ "$n" -gt 0 ] || return 0
  for i in $(seq 1 "$n"); do
    LAUNCHED=$((LAUNCHED + 1))
    ( exec curl -sS --fail-with-body --tcp-nodelay -H "Expect:" \
        -m "$UPLOAD_TIMEOUT" -X PUT "$UPLOAD_URL" \
        -H "x-obs-meta-project-id: $HDR_META" \
        -H "x-obs-acl: $HDR_ACL" \
        -H "x-obs-callback: $HDR_CB" \
        -H "Content-Type: application/octet-stream" \
        -o /dev/null --data-binary "@$BOTTLE" \
        -w '%{http_code} %{time_total} %{size_upload} %{speed_upload}' \
        >"$UPLOAD_DIR/$LAUNCHED.code" 2>"$UPLOAD_DIR/$LAUNCHED.err" ) &
    PIDS+=("$!")
  done
  echo "== hedged PUT $FILENAME ($SIZE B): connections $((LAUNCHED - n + 1))-$LAUNCHED =="
}

# `jobs` is unusable here: inside the $(...) command substitution that reads
# it, a subshell reports no jobs of its own, so every curl looked "finished"
# and the hedge kept spawning replacements while the first wave was still
# uploading (caught by a local mock before the second live run). Track the
# pids we launched instead; exec means each pid IS curl.
count_alive() {
  local n=0 i
  for i in $(seq 1 "$LAUNCHED"); do
    [ -s "$UPLOAD_DIR/$i.code" ] && continue
    kill -0 "${PIDS[$((i - 1))]}" 2>/dev/null && n=$((n + 1))
  done
  echo "$n"
}

report_conns() {
  local f
  for f in "$UPLOAD_DIR"/*.code; do
    [ -e "$f" ] || continue
    echo "  conn $(basename "$f" .code): [$(cat "$f" 2>/dev/null)] err=[$(tr '\r' '\n' <"${f%.code}.err" 2>/dev/null | grep -vE '^[[:space:]]*$' | tail -1)]"
  done
}

WINNER=""
start_wave "$TARGET"
WAVE_AT=$SECONDS
DEADLINE=$((SECONDS + UPLOAD_TIMEOUT))
while :; do
  for f in "$UPLOAD_DIR"/*.code; do
    [ -s "$f" ] || continue
    # curl's -w output has no trailing newline, so `read` returns EOF (non-zero)
    # while still filling the variable — read the code with awk instead of
    # gating on read's exit status.
    code=$(awk 'NR==1{print $1; exit}' "$f" 2>/dev/null || true)
    case "$code" in
      2[0-9][0-9])
        WINNER=$f
        break 2
        ;;
    esac
  done
  ALIVE=$(count_alive)
  # An unlucky start should not be waited out: widen before replacing, so the
  # replacements below fill the new target.
  if [ "$TARGET" -lt "$HEDGE_MAX" ] && [ $((SECONDS - WAVE_AT)) -ge "$WAVE_DELAY" ]; then
    TARGET=$((TARGET + HEDGE))
    [ "$TARGET" -gt "$HEDGE_MAX" ] && TARGET=$HEDGE_MAX
    WAVE_AT=$SECONDS
    echo "::notice::no completion after $((SECONDS))s; widening the hedge to $TARGET connections"
  fi
  if [ "$ALIVE" -lt "$TARGET" ] && [ "$LAUNCHED" -lt "$HEDGE_ATTEMPTS" ]; then
    BATCH=$((TARGET - ALIVE))
    [ $((LAUNCHED + BATCH)) -gt "$HEDGE_ATTEMPTS" ] && BATCH=$((HEDGE_ATTEMPTS - LAUNCHED))
    echo "::notice::$ALIVE of $TARGET connections still running; starting $BATCH replacements"
    start_wave "$BATCH"
  fi
  if [ "$ALIVE" -eq 0 ] && [ "$LAUNCHED" -ge "$HEDGE_ATTEMPTS" ]; then
    echo "::error::all $LAUNCHED hedged upload connections failed"
    report_conns
    break
  fi
  if [ "$SECONDS" -ge "$DEADLINE" ]; then
    echo "::error::hedged bottle upload did not finish within ${UPLOAD_TIMEOUT}s"
    report_conns
    break
  fi
  sleep 2
done

kill "${PIDS[@]}" 2>/dev/null || true
wait 2>/dev/null || true
[ -n "$WINNER" ] || { rm -rf "$UPLOAD_DIR"; exit 1; }
echo "::notice::hedged upload won by connection $(basename "$WINNER" .code): $(cat "$WINNER")"
report_conns

# The asset only becomes downloadable once the OBS callback registers it, and
# that can lag the PUT by a few seconds, so poll the byte count instead of
# trusting the 2xx alone. A mismatch means a truncated object: fail here,
# before the bottle commit is pushed.
ACTUAL=""
for _ in $(seq 1 20); do
  # `|| true` matters: lib.sh sets pipefail, and a transient CDN error here
  # must not abort a publish whose upload already succeeded.
  ACTUAL=$(curl -sSL -m 60 -r 0-0 -o /dev/null -D - \
    "https://atomgit.com/social4hyq/homebrew-core/releases/download/$TAG/$FILENAME" 2>/dev/null \
    | tr -d '\r' | awk 'tolower($1)=="content-range:"{print $3}' | cut -d/ -f2 || true)
  [ "$ACTUAL" = "$SIZE" ] && break
  sleep 3
done
[ "$ACTUAL" = "$SIZE" ] || {
  echo "::error::published asset is ${ACTUAL:-nothing} bytes, expected $SIZE; refusing to push the bottle commit"
  rm -rf "$UPLOAD_DIR"
  exit 1
}
echo "published asset size verified: $ACTUAL bytes"

# Losers are killed within ~2s of the winner, but two near-tied connections
# can both complete and atomgit then lists the same attachment name twice.
# Both carry identical bytes; this only keeps the release tidy.
ATTACH_IDS=$(ag "$API/releases/tags/$TAG" | jq -r --arg n "$FILENAME" '.assets[]?|select(.name==$n)|.id' || true)
ATTACH_COUNT=$(grep -c . <<<"$ATTACH_IDS" || true)
if [ "${ATTACH_COUNT:-0}" -gt 1 ]; then
  echo "::warning::$ATTACH_COUNT attachments named $FILENAME; removing all but the last"
  for id in $(head -n $((ATTACH_COUNT - 1)) <<<"$ATTACH_IDS"); do
    ag -X DELETE "$API/releases/$TAG/attach_files/$id" || true
  done
fi
rm -rf "$UPLOAD_DIR"

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
