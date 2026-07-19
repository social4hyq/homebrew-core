#!/bin/bash
# Upload the bottle to the atomgit release $TAG, merge the bottle block back
# into the formula, and push both remotes.
source "$(dirname "$0")/lib.sh"

API=https://atomgit.com/api/v5/repos/social4hyq/homebrew-core
ag() { curl -sf -m 30 -H "Authorization: Bearer $ATOMGIT_TOKEN" "$@"; }

BOTTLE=$(ls bottle-out/*.tar.gz | head -1)
FILENAME=$(basename "$BOTTLE")

# 1. get-or-create release (atomgit returns no release id; keyed by tag)
# TODO(M3): a flaky GET falls through to POST and hits a confusing 409
ag "$API/releases/tags/$TAG" \
  || ag -X POST -H "Content-Type: application/json" \
       -d "{\"tag_name\":\"$TAG\",\"name\":\"$TAG\",\"target_commitish\":\"main\",\"body\":\"$TAG bottle (CI run $RUN_NUMBER)\"}" \
       "$API/releases"

# 2. presigned upload URL (file_name required), then PUT to OBS object storage
RESP=$(ag "$API/releases/$TAG/upload_url?file_name=$FILENAME")
curl -sf -m 300 -X PUT "$(echo "$RESP" | jq -r .url)" \
  -H "x-obs-meta-project-id: $(echo "$RESP" | jq -r '.headers["x-obs-meta-project-id"]')" \
  -H "x-obs-acl: $(echo "$RESP" | jq -r '.headers["x-obs-acl"]')" \
  -H "x-obs-callback: $(echo "$RESP" | jq -r '.headers["x-obs-callback"]')" \
  -H "Content-Type: application/octet-stream" \
  --data-binary "@$BOTTLE" -w "HTTP=%{http_code}\n"

# 3. merge bottle block back (--merge takes the json file, not the formula name)
docker exec -w "$TAP_IN_CONTAINER/bottle-out" "$CONTAINER" bash -lc \
  "$BREW_ENV brew bottle --merge --write ./*.bottle.json"
# brew committed as root in-container; restore ownership before git push
sudo chown -R "$(id -u):$(id -g)" "$GITHUB_WORKSPACE"

# 4. push both remotes. Concurrency is per-formula, so parallel uploads of
#    different formulae can race non-fast-forward: fetch+rebase and retry.
#    A real rebase conflict aborts via set -e rather than force-pushing.
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add Formula/
git diff --cached --quiet || git commit -m "bottle($FORMULA): rebuild bottle $TAG"

# main requires PRs (ruleset); actions/checkout's ephemeral GITHUB_TOKEN
# can't bypass that, so drop its extraheader and push with the admin PAT
# below instead (an explicit bypass actor on the ruleset).
git config --unset-all http.https://github.com/.extraheader || true
GH_PUSH_URL="https://social4hyq:${BOT_PUSH_TOKEN}@github.com/social4hyq/homebrew-core.git"
for i in 1 2 3; do
  if git push "$GH_PUSH_URL" HEAD:main; then
    break
  fi
  [ "$i" = 3 ] && { echo "::error::push origin failed 3 times; atomgit release $TAG already uploaded, verify the bottle merge manually"; exit 1; }
  echo "::warning::push origin rejected (concurrent upload?), fetch+rebase retry ($i/3)"
  git fetch origin main
  git rebase origin/main
  sleep 5
done
git push "https://social4hyq:${ATOMGIT_TOKEN}@atomgit.com/social4hyq/homebrew-core.git" HEAD:main \
  || {
    echo "::warning::atomgit push failed; GitHub updated, sync atomgit manually"
    echo "- ⚠️ atomgit push failed for $TAG — remotes diverged, sync atomgit manually" >> "$GITHUB_STEP_SUMMARY"
  }
