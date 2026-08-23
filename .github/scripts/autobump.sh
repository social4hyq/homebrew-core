#!/bin/bash
# Open a bump-formula-pr for each $ALLOWLIST formula with a newer upstream
# livecheck version (optionally narrowed to $ONLY_FORMULA).
#
# `brew bump-formula-pr` does the valuable part (resolve the new version,
# fetch the release to compute its checksum, edit the formula, commit, push
# the branch) but its own "open the PR" step is hardcoded to AtomGit's API
# regardless of the tap's actual remote (confirmed 2026-07-20 — this is
# Harmonybrew's own upstream fork, built for their AtomGit-hosted tap; ours
# lives on GitHub, AtomGit is just a mirror). So it always "fails" at that
# last step even on a fully successful run — expected, not an error. The
# branch it already pushed to GitHub is what we actually care about; this
# script opens the real GitHub PR itself once that branch exists.
#
# Uses GITHUB_TOKEN (github-actions[bot]), not a personal PAT: this only
# ever pushes a fresh bump-<formula>-<version> branch and opens/labels a PR
# against it, neither of which needs the ruleset-bypass admin PAT that
# pushing bottle commits directly to protected main requires (see
# publish.sh). Needs repo setting "Allow GitHub Actions to create and
# approve pull requests" (can_approve_pull_request_reviews) enabled —
# flipped on 2026-07-21, previously this whole script ran as social4hyq's
# personal account instead of a bot identity (spotted by comparing PR
# authorship against Homebrew/homebrew-core's BrewTestBot-authored PRs).
source "$(dirname "$0")/lib.sh"

: "${ALLOWLIST:?ALLOWLIST env var required (space-separated formula names)}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN env var required}"

# Retry: livecheck exits 1 (silently, in --json mode — the error only lands in
# the JSON as a per-formula status) when a livecheck URL returns 200 with a
# non-JSON body (observed 2026-08-23: a Cloudflare/npm interstitial during the
# scheduled run; the retry 17min later was clean). Fetch failures that surface
# as HTTP errors don't set Homebrew.failed (exit 0 + error status) — only the
# strategy-block exceptions (JSON.parse on a 200) do.
# On final failure, dump the per-formula error statuses from the LAST JSON
# output before dying: the $() capture holds stdout even on exit 1, and that
# JSON names the failing formula + reason — without this the failure is a
# bare "exit code 1" with zero diagnostics (observed 2026-08-23, run 32618169431).
JSON=""
for attempt in 1 2 3; do
  if JSON=$(cbrew "livecheck --tap $TAP --json --newer-only"); then
    break
  fi
  echo "::warning::brew livecheck failed (attempt $attempt/3)"
  if [ "$attempt" = 3 ]; then
    echo "::error::brew livecheck failed after 3 attempts; per-formula errors from the last attempt:"
    if [ -n "$JSON" ] && ERRORS=$(jq -r '.[] | select(.status == "error") | "\(.formula): \(.messages | join("; "))"' <<< "$JSON" 2>/dev/null) && [ -n "$ERRORS" ]; then
      echo "$ERRORS"
    else
      echo "(no parseable JSON captured — stdout was empty or not JSON; likely a brew-level failure, not a livecheck strategy error)"
    fi
    exit 1
  fi
  sleep 30
done

mapfile -t CANDIDATES < <(
  jq -r --arg allow "$ALLOWLIST" --arg only "${ONLY_FORMULA:-}" '
    ($allow | split(" ")) as $allow
    | .[] | select(.version.latest != null)
    | select(.formula as $f | $allow | index($f))
    | select($only == "" or .formula == $only)
    | "\(.formula)\t\(.version.latest)"
  ' <<< "$JSON"
)

echo "### autobump" >> "$GITHUB_STEP_SUMMARY"

if [ "${#CANDIDATES[@]}" -eq 0 ]; then
  echo "No allowlisted formula has a newer upstream version." >> "$GITHUB_STEP_SUMMARY"
  exit 0
fi

# setup-container.sh drops actions/checkout's ephemeral extraheader (its
# credential helper config doesn't propagate into the container's separate
# environment), but bump-formula-pr's own `git push` doesn't inject
# HOMEBREW_GITHUB_API_TOKEN into git's credentials itself; without a
# replacement it fails outright ("could not read Username", confirmed
# 2026-07-20). Rewrite every https://github.com/ URL to embed GITHUB_TOKEN
# (x-access-token is the standard username for the Actions token, same as
# actions/checkout uses) so any git push bump-formula-pr constructs picks
# it up transparently, regardless of the exact URL shape it builds.
docker exec "$CONTAINER" bash -lc \
  "git config --global url.\"https://x-access-token:${GITHUB_TOKEN}@github.com/\".insteadOf \"https://github.com/\""

for line in "${CANDIDATES[@]}"; do
  FORMULA=$(cut -f1 <<< "$line")
  LATEST=$(cut -f2 <<< "$line")
  echo "== $FORMULA -> $LATEST =="

  # Every iteration must branch off main, not whatever branch the previous
  # formula left behind: bump-formula-pr (and the custom git-revision path
  # below) `git checkout -b` from the current branch, so without this the
  # 2nd/3rd formula's bump branch inherits the 1st's commits and its PR spans
  # multiple formulae (observed 2026-07-31: PR #119/#120 both carried
  # ohos-opencode's bump commit). Nothing is left uncommitted between
  # iterations, so a plain checkout is safe.
  docker exec "$CONTAINER" bash -lc "cd \"$TAP_IN_CONTAINER\" && git checkout -q main"

  # Git-revision formulae (stable url is a .git URL with a `revision:` pin,
  # bun.rb pattern) can't use bump-formula-pr: its version comparison
  # (bump-formula-pr.rb: 302-314) hard-rejects "new version == old version"
  # with no --force escape, and a fixed-version bump never changes the
  # version. So we bump these ourselves — commit, push, open the PR — same
  # ci-passed/bump-formula-pr labels + automerge path as a bump-formula-pr PR.
  #
  # Two sub-schemes, keyed on what livecheck reports:
  #   a) a 40-hex commit sha (fixed version + commit-sha livecheck, e.g.
  #      bun.rb): bump the git revision pin + increment the brew `revision N`
  #      (effective version advances <ver>_N, which is what drives the
  #      new-bottle pipeline in pr-validate).
  #   b) an npm version (opencode@2: livecheck follows the npm beta dist-tag
  #      and the formula `version` mirrors it): map the npm version to the
  #      branch tip at its npm publish timestamp (upstream CI publishes the
  #      tip per merge; npm metadata carries no gitHead — verified
  #      2026-08-22: beta-17898 published 07:02Z, tip-at-that-time committed
  #      06:53Z), then bump `version` + the pin and drop any brew `revision`
  #      stanza (Homebrew convention: revision resets on version change).
  #
  # Also defends against a livecheck quirk: for a sha-scheme formula the
  # commit SHA always sorts above the version string, so `--newer-only` keeps
  # reporting it as outdated even when the pin is already at HEAD — compare
  # the actual pin (sha scheme) / formula version (npm scheme) instead.
  FORMULA_PATH=$(docker exec "$CONTAINER" bash -lc \
    "ls \"$TAP_IN_CONTAINER\"/Formula/*/\"$FORMULA\".rb 2>/dev/null | head -1")
  if [ -n "$FORMULA_PATH" ] && docker exec "$CONTAINER" grep -qE 'url .*\.git.*revision:' "$FORMULA_PATH"; then
    CURRENT_REV=$(docker exec "$CONTAINER" grep -oE 'revision: "[0-9a-fA-F]{40}"' "$FORMULA_PATH" | head -1 | cut -d'"' -f2)
    if [ -z "$CURRENT_REV" ]; then
      echo "::error::$FORMULA: git-revision formula but no revision pin found"
      echo "- ⚠️ $FORMULA: no revision pin found" >> "$GITHUB_STEP_SUMMARY"
      continue
    fi

    FORMULA_VERSION=$(docker exec "$CONTAINER" grep -oE '^  version "[^"]+"' "$FORMULA_PATH" | head -1 | cut -d'"' -f2)

    # npm-version scheme (opencode@2): resolve the git sha for LATEST.
    # These lookups run on the runner host (not the OHOS container).
    TARGET_SHA=""
    NEW_VERSION="$FORMULA_VERSION"
    EDIT_VERSION=false
    if [[ "$LATEST" =~ ^[0-9a-fA-F]{40}$ ]]; then
      if [ "$CURRENT_REV" = "$LATEST" ]; then
        echo "::notice::$FORMULA: already at HEAD $LATEST (livecheck reports it anyway — commit SHA sorts above the fixed version), skipping"
        echo "- ⏭️ $FORMULA: already at HEAD $LATEST" >> "$GITHUB_STEP_SUMMARY"
        continue
      fi
      TARGET_SHA="$LATEST"
    else
      if [ "$FORMULA_VERSION" = "$LATEST" ]; then
        echo "::notice::$FORMULA: already at $LATEST, skipping"
        echo "- ⏭️ $FORMULA: already at $LATEST" >> "$GITHUB_STEP_SUMMARY"
        continue
      fi
      # npm-scheme mapping is formula-specific (package, repo, branch).
      case "$FORMULA" in
        opencode@2)
          NPM_PACKAGE="@opencode-ai/cli"
          GIT_REPO="anomalyco/opencode"
          GIT_BRANCH="v2"
          ;;
        *)
          echo "::error::$FORMULA: livecheck returned a non-sha version '$LATEST' but no npm→git mapping is configured for it"
          echo "- ❌ $FORMULA: no npm→git mapping" >> "$GITHUB_STEP_SUMMARY"
          continue
          ;;
      esac
      # `|| true` inside the $(): this script runs `bash -euo pipefail`, so an
      # unguarded `VAR=$(curl|jq)` whose pipeline fails (network, HTTP error)
      # would kill the script AT THE ASSIGNMENT — silently, before the -z
      # checks below can route it to a per-formula ::error:: (observed
      # 2026-08-23 as a bare "exit code 1" with zero output). --retry rides
      # out transient runner-network blips; -S surfaces curl errors in the
      # log for diagnosis even though -s quiets the progress meter.
      PUBLISHED=$(curl -fsSL --retry 3 --retry-delay 2 \
        "https://registry.npmjs.org/$NPM_PACKAGE" \
        | jq -r --arg v "$LATEST" '.time[$v] // empty' || true)
      if [ -z "$PUBLISHED" ]; then
        echo "::error::$FORMULA: npm has no publish timestamp for $LATEST"
        echo "- ❌ $FORMULA: no npm timestamp for $LATEST" >> "$GITHUB_STEP_SUMMARY"
        continue
      fi
      TARGET_SHA=$(curl -fsSL --retry 3 --retry-delay 2 \
        "https://api.github.com/repos/$GIT_REPO/commits?sha=$GIT_BRANCH&per_page=1&until=$PUBLISHED" \
        | jq -r '.[0].sha // empty' || true)
      if [ -z "$TARGET_SHA" ]; then
        echo "::error::$FORMULA: could not resolve a $GIT_BRANCH tip for $LATEST (published $PUBLISHED)"
        echo "- ❌ $FORMULA: version→sha resolution failed" >> "$GITHUB_STEP_SUMMARY"
        continue
      fi
      NEW_VERSION="$LATEST"
      EDIT_VERSION=true
    fi

    if [ "$EDIT_VERSION" = true ]; then
      BRANCH="bump-${FORMULA}-${NEW_VERSION}"
      echo "npm-version formula: version $FORMULA_VERSION -> $NEW_VERSION, pin $CURRENT_REV -> $TARGET_SHA (brew revision stanza dropped)"
      EDIT_AND_VERIFY="
        set -euo pipefail
        sed -i 's/revision: \"$CURRENT_REV\"/revision: \"$TARGET_SHA\"/' \"$FORMULA_PATH\"
        sed -i 's/^  version \"[^\"]*\"/  version \"$NEW_VERSION\"/' \"$FORMULA_PATH\"
        sed -i '/^  revision [0-9][0-9]*$/d' \"$FORMULA_PATH\"
        grep -q 'revision: \"$TARGET_SHA\"' \"$FORMULA_PATH\"
        grep -q '^  version \"[^\"]*\"' \"$FORMULA_PATH\"
        ! grep -qE '^  revision [0-9]' \"$FORMULA_PATH\"
      "
    else
      # REV_N lives ONLY in the sha scheme: npm-scheme formulae have no
      # `revision N` stanza, and an unguarded no-match grep kills this script
      # at the assignment under `set -e + pipefail` (observed 2026-08-23:
      # bare exit 1, zero output, 0.6s after the candidate echo). The
      # trailing `|| true` tolerates both the no-match and docker hiccups;
      # REV_N=${REV_N:-0} only runs once the assignment itself can't throw.
      REV_N=$(docker exec "$CONTAINER" grep -oE '^  revision [0-9]+' "$FORMULA_PATH" \
        | grep -oE '[0-9]+' | head -1 || true)
      REV_N=${REV_N:-0}
      NEXT_REV_N=$((REV_N + 1))
      NEW_VERSION="${FORMULA_VERSION}_${NEXT_REV_N}"
      BRANCH="bump-${FORMULA}-${NEW_VERSION}"
      echo "git-revision formula: pin $CURRENT_REV -> $LATEST, brew revision $REV_N -> $NEXT_REV_N"
      EDIT_AND_VERIFY="
        set -euo pipefail
        sed -i 's/revision: \"$CURRENT_REV\"/revision: \"$TARGET_SHA\"/' \"$FORMULA_PATH\"
        sed -i 's/^  revision $REV_N\$/  revision $NEXT_REV_N/' \"$FORMULA_PATH\"
        grep -q 'revision: \"$TARGET_SHA\"' \"$FORMULA_PATH\"
        grep -q '^  revision $NEXT_REV_N' \"$FORMULA_PATH\"
      "
    fi

    if ! docker exec "$CONTAINER" bash -lc "$EDIT_AND_VERIFY"; then
      echo "::error::$FORMULA: formula edit/verify failed"
      echo "- ❌ $FORMULA: formula edit failed" >> "$GITHUB_STEP_SUMMARY"
      continue
    fi

    set +e
    OUT=$(timeout 120 docker exec "$CONTAINER" bash -lc "
      cd \"$TAP_IN_CONTAINER\"
      git checkout -b \"$BRANCH\" 2>&1 &&
      git add \"$FORMULA_PATH\" 2>&1 &&
      git commit -m \"$FORMULA: update to $LATEST\" 2>&1 &&
      git push -u origin \"$BRANCH\" 2>&1
    " 2>&1)
    STATUS=$?
    set -e
    [ "$STATUS" -eq 124 ] && echo "::warning::$FORMULA git push TIMED OUT after 120s"
    echo "$OUT"

    if ! git ls-remote --exit-code --heads \
         "https://x-access-token:${GITHUB_TOKEN}@github.com/social4hyq/homebrew-core.git" "$BRANCH" \
         > /dev/null 2>&1; then
      echo "::warning::$FORMULA didn't push $BRANCH — see log above"
      echo "- ⚠️ $FORMULA $LATEST: no branch pushed, see job log" >> "$GITHUB_STEP_SUMMARY"
      continue
    fi

    EXISTING=$(gh pr list --repo social4hyq/homebrew-core --head "$BRANCH" --state open --json url --jq '.[0].url // empty')
    if [ -n "$EXISTING" ]; then
      echo "- ⏭️ $FORMULA $LATEST: PR already open: $EXISTING" >> "$GITHUB_STEP_SUMMARY"
      continue
    fi

    if [ "$EDIT_VERSION" = true ]; then
      PR_BODY="Automated npm-version bump ($FORMULA beta dist-tag). Custom autobump path: livecheck follows the npm beta dist-tag; the git pin is remapped to the branch tip at that npm release's publish timestamp (npm metadata has no gitHead). CI builds the new commit and publishes the bottle."
    else
      PR_BODY="Automated commit-pin bump ($FORMULA v2 branch HEAD). Custom autobump path for git-revision formulae (bun.rb pattern): bump-formula-pr rejects fixed-version bumps, so this updates the git revision pin and increments the brew revision. CI builds the new commit and publishes the bottle."
    fi

    PR_URL=$(gh pr create --repo social4hyq/homebrew-core \
      --head "$BRANCH" --base main \
      --title "$FORMULA $NEW_VERSION" \
      --body "$PR_BODY" \
      ) || { echo "::error::$FORMULA: gh pr create failed after a successful push"; echo "- ❌ $FORMULA $LATEST: push OK, gh pr create failed" >> "$GITHUB_STEP_SUMMARY"; continue; }

    PR_NUM="${PR_URL##*/}"
    gh pr edit "$PR_NUM" --repo social4hyq/homebrew-core --add-label bump-formula-pr
    echo "- ✅ $FORMULA $LATEST: $PR_URL" >> "$GITHUB_STEP_SUMMARY"
    continue
  fi

  set +e
  # timeout guard: a hang here (e.g. a future git-config regression) should
  # fail this one formula fast, not silently burn the whole job's 30min
  # budget (happened during 2026-07-20 debugging of the remote-repository
  # issue this script used to hit)
  OUT=$(timeout 300 docker exec -e HOMEBREW_GITHUB_API_TOKEN="$GITHUB_TOKEN" "$CONTAINER" bash -lc \
    "$BREW_ENV brew bump-formula-pr --no-audit --no-browse --no-fork --version=$LATEST $TAP/$FORMULA" 2>&1)
  STATUS=$?
  set -e
  [ "$STATUS" -eq 124 ] && echo "::warning::$FORMULA bump-formula-pr TIMED OUT after 300s"
  echo "$OUT"

  # Deterministic branch name bump-formula-pr uses internally
  # (Homebrew::Bump::BumpInfo#branch_name: "bump-#{formula}-#{version}").
  BRANCH="bump-${FORMULA}-${LATEST}"

  if ! git ls-remote --exit-code --heads \
       "https://x-access-token:${GITHUB_TOKEN}@github.com/social4hyq/homebrew-core.git" "$BRANCH" \
       > /dev/null 2>&1; then
    echo "::warning::$FORMULA bump-formula-pr didn't push $BRANCH — a real failure (audit/fetch/checksum), see log above"
    echo "- ⚠️ $FORMULA $LATEST: no branch pushed, see job log" >> "$GITHUB_STEP_SUMMARY"
    continue
  fi

  EXISTING=$(gh pr list --repo social4hyq/homebrew-core --head "$BRANCH" --state open --json url --jq '.[0].url // empty')
  if [ -n "$EXISTING" ]; then
    echo "- ⏭️ $FORMULA $LATEST: PR already open: $EXISTING" >> "$GITHUB_STEP_SUMMARY"
    continue
  fi

  PR_URL=$(gh pr create --repo social4hyq/homebrew-core \
    --head "$BRANCH" --base main \
    --title "$FORMULA $LATEST" \
    --body "Automated version bump via \`brew bump-formula-pr\` (autobump.yml, formula edit/checksum computed by brew; PR opened here since bump-formula-pr's own PR step is AtomGit-only in this Homebrew fork).") \
    || { echo "::error::$FORMULA: gh pr create failed after a successful push"; echo "- ❌ $FORMULA $LATEST: push OK, gh pr create failed" >> "$GITHUB_STEP_SUMMARY"; continue; }

  PR_NUM="${PR_URL##*/}"
  gh pr edit "$PR_NUM" --repo social4hyq/homebrew-core --add-label bump-formula-pr
  echo "- ✅ $FORMULA $LATEST: $PR_URL" >> "$GITHUB_STEP_SUMMARY"
done
