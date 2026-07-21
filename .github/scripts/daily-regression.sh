#!/bin/bash
# Daily cascading regression test.
#
# Formula-api/git-tap based reverse-dependency graph (`brew uses --recursive`)
# scans EVERY tapped repo, not just ours — on the shared debugging container
# (which also has other taps) it returned hundreds of unrelated homebrew/core
# formulae for icu4c@78 (2026-07-20). Building the reverse-dep map by
# grepping our own Formula/*/*.rb `depends_on` lines instead is self-scoped,
# deterministic, and needs no live brew environment at all.
#
# Idea adapted from Harmonybrew/ci's auto_dailytest.py: catch a change to a
# base formula (llvm@21) silently breaking a downstream one (icu4c@78 →
# bun-webkit → bun → ohos-opencode) that a PR-scoped build would never touch.
source "$(dirname "$0")/lib.sh"

TAP_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$TAP_DIR"

SINCE="${SINCE:-24 hours ago}"
TEST_TIMEOUT="${TEST_TIMEOUT:-180}"

# ── Step 1: current formula set + static reverse-dep map ──────────────
# depends_on "foo" / depends_on "social4hyq/core/foo" => :build/:test/[...]
# Only pairs where the dependency is itself a formula in this tap matter —
# cross-tap deps (ohos-sdk, llvm's cmake/ninja, etc.) can't cascade-break
# anything we own.
declare -A ALL_FORMULAE=()
while IFS= read -r f; do
  name="$(basename "$f" .rb)"
  ALL_FORMULAE["$name"]=1
done < <(find Formula -name '*.rb')

declare -A DEPENDENTS=()  # dep -> space-separated list of formulae that depend on it
for f in Formula/*/*.rb; do
  formula="$(basename "$f" .rb)"
  while IFS= read -r dep; do
    dep="${dep#social4hyq/core/}"
    [ -n "${ALL_FORMULAE[$dep]:-}" ] || continue
    [ "$dep" = "$formula" ] && continue
    DEPENDENTS["$dep"]="${DEPENDENTS[$dep]:-} $formula"
  done < <(grep -oE '^\s*depends_on\s+"[^"]+"' "$f" | sed -E 's/^\s*depends_on\s+"([^"]+)"/\1/')
done

# ── Step 2: formulae touched since $SINCE, still present in the tap ────
# A rename/delete inside the window would otherwise leave a since-removed
# name in CHANGED, and `brew install` on it fails as a false "regression".
mapfile -t CHANGED < <(
  git log --since="$SINCE" --name-only --pretty=format: -- 'Formula/*.rb' \
    | grep -E '^Formula/.+\.rb$' \
    | sed -E 's#^Formula/[^/]+/(.+)\.rb$#\1#' \
    | sort -u \
    | while IFS= read -r name; do [ -n "${ALL_FORMULAE[$name]:-}" ] && echo "$name"; done
)

if [ "${#CHANGED[@]}" -eq 0 ]; then
  echo "No formula changes in the last $SINCE, nothing to regression-test." | tee -a "$GITHUB_STEP_SUMMARY"
  exit 0
fi
echo "Changed since $SINCE: ${CHANGED[*]}"

# ── Step 3: transitive closure of changed ∪ dependents ─────────────────
declare -A TEST_SET=()
QUEUE=("${CHANGED[@]}")
for f in "${CHANGED[@]}"; do TEST_SET["$f"]=1; done
while [ "${#QUEUE[@]}" -gt 0 ]; do
  f="${QUEUE[0]}"; QUEUE=("${QUEUE[@]:1}")
  for dep in ${DEPENDENTS[$f]:-}; do
    if [ -z "${TEST_SET[$dep]:-}" ]; then
      TEST_SET["$dep"]=1
      QUEUE+=("$dep")
    fi
  done
done

FORMULAE=($(printf '%s\n' "${!TEST_SET[@]}" | sort))
echo "Test set (${#FORMULAE[@]}): ${FORMULAE[*]}"

# ── Step 4: sequential install + test in the shared container ─────────
declare -A RESULT=()
for f in "${FORMULAE[@]}"; do
  echo "::group::$f"
  if cexec "$BREW_ENV brew install --formula --include-test $TAP/$f" > install.log 2>&1; then
    if timeout "$TEST_TIMEOUT" docker exec "$CONTAINER" bash -lc "$BREW_ENV brew test $TAP/$f" > test.log 2>&1; then
      RESULT["$f"]="pass"
    elif grep -qi "does not define tests\|defines no test" test.log; then
      RESULT["$f"]="skip"
    else
      RESULT["$f"]="fail (test)"
      tail -30 test.log
    fi
  else
    RESULT["$f"]="fail (install)"
    tail -30 install.log
  fi
  echo "  -> ${RESULT[$f]}"
  echo "::endgroup::"
done

# ── Step 5: summary + tracking issue on failure ────────────────────────
# FAILED must be built in the main shell, not inside the `{...} | tee` pipe
# below (bash runs the left side of a pipeline in a subshell, which would
# make FAILED invisible to the `if` after it).
FAILED=()
TABLE=""
for f in "${FORMULAE[@]}"; do
  icon="✅"
  case "${RESULT[$f]}" in
    fail*) icon="❌"; FAILED+=("$f: ${RESULT[$f]}") ;;
    skip) icon="⏭️" ;;
  esac
  TABLE+="| $f | $icon ${RESULT[$f]} |
"
done

{
  echo "### daily-regression ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
  echo "Changed since $SINCE: ${CHANGED[*]}"
  echo ""
  echo "| formula | result |"
  echo "|---|---|"
  printf '%s' "$TABLE"
} | tee -a "$GITHUB_STEP_SUMMARY"

TITLE="Daily regression: cascading test failures"
RUN_URL="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-social4hyq/homebrew-core}/actions/runs/${GITHUB_RUN_ID:-}"
EXISTING=$(gh issue list --repo social4hyq/homebrew-core --search "in:title \"$TITLE\"" --state open --json number --jq '.[0].number // empty')

if [ "${#FAILED[@]}" -gt 0 ]; then
  BODY=$'Auto-updated by daily-regression.yml. Do not edit by hand.\n\n'"Run: $RUN_URL"$'\n\n'"$(printf -- '- %s\n' "${FAILED[@]}")"
  if [ -n "$EXISTING" ]; then
    gh issue comment "$EXISTING" --repo social4hyq/homebrew-core --body "$BODY"
  else
    gh issue create --repo social4hyq/homebrew-core --title "$TITLE" --body "$BODY"
  fi
  exit 1
fi

# Green run: close the tracking issue if one is open. Without this, a
# transient failure (2026-07-20: codex's ripgrep dep 404'd on the upstream
# harmonybrew.atomgit.com bottle CDN, issue #46) leaves the issue open
# forever after things recover. Caveat stated in the closing comment: the
# test set is last-24h-touched + dependents, so a green run means "no
# current failures", not necessarily a re-test of the formula that failed —
# a real recurrence just opens a fresh issue on the next failing run.
if [ -n "$EXISTING" ]; then
  gh issue close "$EXISTING" --repo social4hyq/homebrew-core --comment \
    "Auto-closing on green run: $RUN_URL

Note: the test set is last-24h-touched formulae + dependents, so this means \"no current failures\" — not necessarily a re-test of the formula that originally failed. A recurrence will open a fresh issue."
fi
