#!/usr/bin/env bash
# Set or clear the ci-passed label from the real gate state.
#
# This is the last job of pr-validate and runs with `if: always()`, so a
# failing run actively REMOVES a stale ci-passed label instead of leaving one
# behind. Force-push, rerun and bottle write-back all used to leave a green
# label on a red PR because the label job was skipped on failure.
#
# The label is also withheld when any gate check in the PR's history has a
# failing verdict. Gate checks are aggregated across all commits by name,
# taking the last non-skipped conclusion: an explicit rerun/dispatch that
# turned a check green clears an older failure, while a bottle write-back
# re-trigger whose light-check/build are skipped cannot launder a failure on
# an earlier code commit (skipped is not a verdict).
set -euo pipefail

GH="${GH:-gh}"
REPO="${REPO:?REPO is required}"
PR="${PR:?PR is required}"
LINT="${LINT:-}"
HAP="${HAP:-}"
DETECT="${DETECT:-}"
LIGHT="${LIGHT:-}"
BUILD="${BUILD:-}"

reason=""

# Current run's own gates. lint/hap/detect must genuinely pass; light/build
# may be skipped only when their input list was empty (self-triggered run or
# a PR touching a category with no matching formulae).
for pair in "lint-commits:$LINT" "hap-checks:$HAP" "detect:$DETECT"; do
  name="${pair%%:*}"
  val="${pair#*:}"
  if [ "$val" != "success" ]; then
    reason="current run: $name=$val (need success)"
    break
  fi
done
if [ -z "$reason" ]; then
  for pair in "light-check:$LIGHT" "build:$BUILD"; do
    name="${pair%%:*}"
    val="${pair#*:}"
    case "$val" in
      success|skipped) ;;
      *)
        reason="current run: $name=$val (need success or skipped)"
        break
        ;;
    esac
  done
fi

# History check: aggregate gate checks across every commit in the PR by check
# name, taking the LAST NON-skipped conclusion as the real verdict. This has
# two properties that a per-commit scan misses:
#   - a rerun or an explicit dispatch that turned a check green (newer check
#     run id) clears an older failure, even if that failure lives on a
#     different commit (e.g. a bottle write-back ran the successful rebuild);
#   - a bottle write-back commit whose light-check/build are `skipped` cannot
#     launder a failure on an earlier code commit, because skipped is ignored
#     rather than treated as a newer verdict.
if [ -z "$reason" ]; then
  if ! commits="$($GH api "repos/$REPO/pulls/$PR/commits?per_page=100" --jq '.[].sha' 2>/dev/null)"; then
    reason="could not list PR commits"
    commits=""
  fi
  if [ -z "$reason" ]; then
    checks="$(mktemp "${TMPDIR:-/tmp}/ci-label-checks.XXXXXX")"
    trap 'rm -f "$checks"' EXIT
    : > "$checks"
    for sha in $commits; do
      if ! $GH api "repos/$REPO/commits/$sha/check-runs?per_page=100" \
        --jq '.check_runs[] | [.id, .name, (.conclusion // "pending")] | @tsv' \
        >> "$checks" 2>/dev/null; then
        reason="could not read check-runs for ${sha:0:9}"
        break
      fi
    done
    if [ -z "$reason" ]; then
      failures="$(sort -t"$(printf '\t')" -k1,1n "$checks" | awk -F'\t' '$3 == "skipped" || $3 == "pending" { next } { last[$2] = $3 } END { for (name in last) if (name ~ /^(lint-commits|hap-checks|light-check|build)/ && (last[name] == "failure" || last[name] == "cancelled" || last[name] == "timed_out")) print name "=" last[name] }')"
      if [ -n "$failures" ]; then
        reason="failing gate check(s) in PR history: $(echo "$failures" | tr '\n' ' ')"
      fi
    fi
  fi
fi

if [ -z "$reason" ]; then
  $GH pr edit "$PR" --add-label ci-passed --repo "$REPO"
  echo "ci-passed added (current run clean, no failing gate in PR history)"
else
  # Always try to remove a stale label so a red PR never advertises ci-passed.
  $GH pr edit "$PR" --remove-label ci-passed --repo "$REPO" 2>/dev/null || true
  echo "ci-passed removed: $reason"
fi
