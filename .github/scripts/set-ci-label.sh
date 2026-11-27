#!/usr/bin/env bash
# Set or clear the ci-passed label from the real gate state.
#
# This is the last job of pr-validate and runs with `if: always()`, so a
# failing run actively REMOVES a stale ci-passed label instead of leaving one
# behind. Force-push, rerun and bottle write-back all used to leave a green
# label on a red PR because the label job was skipped on failure.
#
# The label is also withheld when any commit in the PR has a failing gate
# check. A bottle write-back commit re-triggers pr-validate with its changed
# list empty (detect-changes.sh short-circuits), so light-check and build are
# skipped in that run even when the commit that produced the bottle failed
# them. Without the history check that self-triggered run launders a failed
# PR into ci-passed.
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

# History check: every commit in the PR must have clean gate checks. Use the
# latest conclusion per check name so a rerun that turned red -> green is not
# mistaken for a failure.
if [ -z "$reason" ]; then
  if ! commits="$($GH api "repos/$REPO/pulls/$PR/commits?per_page=100" --jq '.[].sha' 2>/dev/null)"; then
    reason="could not list PR commits"
    commits=""
  fi
  if [ -z "$reason" ]; then
    for sha in $commits; do
      if ! failures="$($GH api "repos/$REPO/commits/$sha/check-runs?per_page=100" \
        --jq '[.check_runs | group_by(.name)[] | .[-1]
               | select(.name | test("^(lint-commits|hap-checks|light-check|build)"))
               | select(.conclusion == "failure" or .conclusion == "cancelled" or .conclusion == "timed_out")] | length' \
        2>/dev/null)"; then
        reason="could not read check-runs for ${sha:0:9}"
        break
      fi
      if [ "${failures:-0}" -gt 0 ]; then
        reason="commit ${sha:0:9} has ${failures} failing gate check(s)"
        break
      fi
    done
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
