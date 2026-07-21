#!/bin/bash
# Upload the bottle to the atomgit release $TAG, merge the bottle block back
# into the formula, and push to $PUSH_REF (default main; a PR's own head
# branch when called from pr-validate.yml — see bottle-build.yml).
source "$(dirname "$0")/lib.sh"

: "${PUSH_REF:=main}"
: "${REASON:=}"

API=https://atomgit.com/api/v5/repos/social4hyq/homebrew-core
ag() { curl -sf -m 30 -H "Authorization: Bearer $ATOMGIT_TOKEN" "$@"; }

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

# 5. push to $PUSH_REF. Concurrency is per-formula, so parallel uploads of
#    different formulae can race non-fast-forward: fetch+rebase and retry.
#    A real rebase conflict aborts via set -e rather than force-pushing.
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add Formula/
COMMIT_MSG="bottle($FORMULA): rebuild bottle $TAG"
[ -n "$REASON" ] && COMMIT_MSG="$COMMIT_MSG

$REASON"
git diff --cached --quiet || git commit -m "$COMMIT_MSG"

# main requires PRs (ruleset); actions/checkout's ephemeral GITHUB_TOKEN
# can't bypass that, so drop its extraheader and push with the admin PAT
# below instead (an explicit bypass actor on the ruleset). Unconditional:
# a PR branch push doesn't strictly need the bypass, but reusing one code
# path for every $PUSH_REF avoids a second credential branch here.
git config --unset-all http.https://github.com/.extraheader || true
GH_PUSH_URL="https://social4hyq:${BOT_PUSH_TOKEN}@github.com/social4hyq/homebrew-core.git"
for i in 1 2 3; do
  if git push "$GH_PUSH_URL" "HEAD:$PUSH_REF"; then
    break
  fi
  [ "$i" = 3 ] && { echo "::error::push to $PUSH_REF failed 3 times; atomgit release $TAG already uploaded, verify the bottle merge manually"; exit 1; }
  echo "::warning::push to $PUSH_REF rejected (concurrent update?), fetch+rebase retry ($i/3)"
  git fetch origin "$PUSH_REF"
  git rebase "origin/$PUSH_REF"
  sleep 5
done
# atomgit main is kept in sync by the sync-to-atomgit workflow, triggered by
# pushes to GitHub main — it hard-fails visibly instead of a silent warning.
# A PR-branch push here isn't main, so it doesn't trigger that sync; atomgit
# picks up the bottle once the PR merges to main like any other change.

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
