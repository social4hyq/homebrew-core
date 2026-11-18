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

printf '\n%s passed, %s failed\n' "$PASS" "$FAILED"
[ "$FAILED" -eq 0 ]
