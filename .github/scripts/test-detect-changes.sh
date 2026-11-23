#!/usr/bin/env bash
# Regression test for .github/scripts/detect-changes.sh.
#
# Builds a scratch repository in which two formulae change at different times
# and runs the real script over it. The case that matters is a pull request
# whose branch was forked before the base branch changed another formula: the
# base branch tip is then not an ancestor of the branch head, and a plain diff
# between them lists that other formula as changed, so it is rebuilt from the
# branch's stale copy and a stale bottle is pushed to the branch (seen on
# #1193: obsidian-app was rebuilt from a revision-5 copy on an opencode-app PR).
# Needs bash, git and jq.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${DETECT_CHANGES_SCRIPT:-$ROOT/.github/scripts/detect-changes.sh}"
[ -f "$SCRIPT" ] || { echo "detect-changes.sh not found: $SCRIPT" >&2; exit 2; }

T="$(mktemp -d "${TMPDIR:-/tmp}/detect-changes-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT
# The scratch repository lives in a subdirectory so that the script's output
# files (kept in $T) never end up in a commit.
mkdir "$T/repo"
cd "$T/repo"
git init -q -b main .
git config user.email test@example.invalid
git config user.name test

PASS=0
FAILED=0
ok() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
bad() { FAILED=$((FAILED + 1)); printf 'FAIL - %s\n       %s\n' "$1" "$2"; }

formula() { # formula NAME REVISION BOTTLE_TAG
  mkdir -p "Formula/${1:0:1}"
  cat > "Formula/${1:0:1}/$1.rb" <<EOF
class Foo < Formula
  revision $2
  bottle do
    root_url "https://example.invalid/$1-$3"
  end
  def install
    puts "$1 $2"
  end
end
EOF
}
commit() { git add -A && git commit -q -m "$1"; }
detect() { # detect BEFORE AFTER -> the build list as one line, e.g. alpha-app,beta-app
  local out="$T/gh-output"
  : > "$out"; : > "$T/gh-summary"
  BEFORE="$1" AFTER="$2" HEAVY_FORMULAS="" GITHUB_OUTPUT="$out" GITHUB_STEP_SUMMARY="$T/gh-summary" \
    bash "$SCRIPT" > "$T/log" 2>&1 || { echo "SCRIPT-FAILED"; return; }
  sed -n 's/^build=//p' "$out" | jq -r 'join(",")'
}
expect() { # expect DESCRIPTION WANT GOT
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "wanted build=[$2], got build=[$3]"; fi
}

# Base A: two formulae, each with a resource directory and a published bottle.
formula alpha-app 5 r2
formula beta-app 6 r5
mkdir -p Resources/alpha-app Resources/beta-app
echo old > Resources/alpha-app/run.sh
echo old > Resources/beta-app/run.sh
commit "base"
A=$(git rev-parse HEAD)

# main moves on: alpha-app is changed and its bottle is written back (like #1191).
formula alpha-app 6 r2
echo new > Resources/alpha-app/run.sh
commit "alpha-app: change (revision 6)"
formula alpha-app 6 r3
commit "alpha-app: update 1.0_6 bottle."
MAIN=$(git rev-parse HEAD)

# A pull request branch forked at A that only changes beta-app.
git checkout -q -b pr-behind "$A"
formula beta-app 7 r5
echo new > Resources/beta-app/run.sh
commit "beta-app: change (revision 7)"
PR_BEHIND=$(git rev-parse HEAD)

# A pull request branch forked at the current main.
git checkout -q -b pr-current "$MAIN"
formula beta-app 7 r5
echo new > Resources/beta-app/run.sh
commit "beta-app: change (revision 7)"
PR_CURRENT=$(git rev-parse HEAD)

# 1. The incident: the base tip is ahead of the branch's fork point.
expect "a PR behind its base builds only what the PR changed" "beta-app" "$(detect "$MAIN" "$PR_BEHIND")"
check_log() { grep -q "comparing from the merge base" "$T/log"; }
if check_log; then ok "and says it fell back to the merge base"; else bad "and says it fell back to the merge base" "no notice in the log"; fi

# 2. A PR that is up to date with its base is unaffected.
expect "an up-to-date PR builds what it changed" "beta-app" "$(detect "$MAIN" "$PR_CURRENT")"
if check_log; then bad "an up-to-date PR does not use the fallback" "the fallback notice was printed"; else ok "an up-to-date PR does not use the fallback"; fi

# 3. A push to main (BEFORE is an ancestor of AFTER) keeps working: a real
#    change is built, a bottle write-back is skipped.
git checkout -q main
formula alpha-app 7 r3
echo newer > Resources/alpha-app/run.sh
commit "alpha-app: change again (revision 7)"
PUSH_CHANGE=$(git rev-parse HEAD)
expect "a push that changes a formula builds it" "alpha-app" "$(detect "$MAIN" "$PUSH_CHANGE")"
formula alpha-app 7 r4
commit "alpha-app: update 1.0_7 bottle."
PUSH_BOTTLE=$(git rev-parse HEAD)
expect "a bottle write-back commit builds nothing" "" "$(detect "$PUSH_CHANGE" "$PUSH_BOTTLE")"

# 4. Resource-only change on a PR is still mapped to its formula.
git checkout -q -b pr-resources "$MAIN"
echo again > Resources/beta-app/run.sh
commit "beta-app: tweak the launcher"
PR_RES=$(git rev-parse HEAD)
expect "a PR that only changes Resources/ rebuilds that formula" "beta-app" "$(detect "$MAIN" "$PR_RES")"

# 5. A PR behind its base that changes nothing in formulae builds nothing.
git checkout -q -b pr-docs "$A"
echo docs > README.md
commit "docs: note"
PR_DOCS=$(git rev-parse HEAD)
expect "a PR behind its base that touches no formula builds nothing" "" "$(detect "$PUSH_BOTTLE" "$PR_DOCS")"

# 6. A merged PR whose branch already carries the bottle write-back. The PR
#    changed the formula and Resources/<formula>/, pr-validate built it and
#    pushed the write-back onto the branch, so the post-merge push must not
#    rebuild it (that rebuild used to publish a second bottle and open a bot PR
#    that conflicted with every open PR on the same formula).
merge_pr() { # merge_pr BRANCH -> merges it into main with a merge commit
  git checkout -q main && git merge -q --no-ff -m "Merge pull request from $1" "$1"
}
git checkout -q main
MAIN6=$(git rev-parse HEAD)
git checkout -q -b pr-merged "$MAIN6"
formula beta-app 8 r5
echo built > Resources/beta-app/run.sh
commit "beta-app: change (revision 8)"
formula beta-app 8 r6
commit "beta-app: update 1.0_8 bottle."
merge_pr pr-merged
expect "a merged PR whose write-back already contains its Resources change builds nothing" \
  "" "$(detect "$MAIN6" "$(git rev-parse HEAD)")"

# 7. Resources changed after the write-back: that change is not in the bottle.
MAIN7=$(git rev-parse HEAD)
git checkout -q -b pr-late "$MAIN7"
formula beta-app 9 r6
echo built > Resources/beta-app/run.sh
commit "beta-app: change (revision 9)"
formula beta-app 9 r7
commit "beta-app: update 1.0_9 bottle."
echo later > Resources/beta-app/run.sh
commit "beta-app: edit the launcher after the build"
merge_pr pr-late
expect "Resources changed after the write-back still rebuilds" \
  "beta-app" "$(detect "$MAIN7" "$(git rev-parse HEAD)")"

# 8. A Resources-only PR on a formula whose last .rb commit is an old write-back.
git checkout -q main
MAIN8=$(git rev-parse HEAD)
git checkout -q -b pr-res-only "$MAIN8"
echo only > Resources/beta-app/run.sh
commit "beta-app: tweak the launcher again"
expect "a Resources-only change after an old write-back rebuilds" \
  "beta-app" "$(detect "$MAIN8" "$(git rev-parse HEAD)")"

# 9. A change under Resources/_shared/<x>/ maps to the formulae that use it,
#    and gets the same treatment.
git checkout -q main
mkdir -p Formula/g Resources/_shared/lib
cat > Formula/g/gamma-app.rb <<'EOF'
class Foo < Formula
  revision 1
  bottle do
    root_url "https://example.invalid/gamma-app-r1"
  end
  def install
    cp "Resources/_shared/lib/x.sh", pkgshare
  end
end
EOF
echo old > Resources/_shared/lib/x.sh
commit "gamma-app: add"
MAIN9=$(git rev-parse HEAD)
git checkout -q -b pr-shared "$MAIN9"
sed -i 's/revision 1/revision 2/' Formula/g/gamma-app.rb
echo new > Resources/_shared/lib/x.sh
commit "gamma-app: change (revision 2)"
sed -i 's/gamma-app-r1/gamma-app-r2/' Formula/g/gamma-app.rb
commit "gamma-app: update 1.0_2 bottle."
merge_pr pr-shared
expect "a shared Resources change already in the write-back builds nothing" \
  "" "$(detect "$MAIN9" "$(git rev-parse HEAD)")"
MAIN9B=$(git rev-parse HEAD)
git checkout -q -b pr-shared-late "$MAIN9B"
echo newer > Resources/_shared/lib/x.sh
commit "shared: edit lib"
expect "a shared Resources change after the write-back rebuilds the formula using it" \
  "gamma-app" "$(detect "$MAIN9B" "$(git rev-parse HEAD)")"

# 10. caveats is user-facing hint text that never lands in the bottle.
#     Adding/removing it alone must not rebuild; a caveats edit together with
#     a real code change still must (the strip must not hide real changes).
git checkout -q main
MAIN10=$(git rev-parse HEAD)
git checkout -q -b pr-caveats "$MAIN10"
sed -i 's/^  def install$/  def caveats\n    <<~EOS\n      hint text\n    EOS\n  end\n\n  def install/' Formula/a/alpha-app.rb
commit "alpha-app: add caveats"
CAVEATS=$(git rev-parse HEAD)
expect "a caveats-only change builds nothing" "" "$(detect "$MAIN10" "$CAVEATS")"
sed -i 's/revision 7/revision 8/' Formula/a/alpha-app.rb
commit "alpha-app: change (revision 8)"
CAVEATS_PLUS=$(git rev-parse HEAD)
expect "caveats plus a real code change still rebuilds" "alpha-app" "$(detect "$MAIN10" "$CAVEATS_PLUS")"

printf '\n%s passed, %s failed\n' "$PASS" "$FAILED"
[ "$FAILED" -eq 0 ]
