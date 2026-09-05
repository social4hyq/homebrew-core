#!/bin/bash
# Reinstall from the published bottle, verify poured_from_bottle, re-run brew test.
# A failure here means the published tag is bad: pull the release, fix, rerun.
source "$(dirname "$0")/lib.sh"

# formula content just changed; re-trust before reinstalling
cexec "brew trust $TAP"
# Get the keg out of the way so `install` re-fetches and pours the PUBLISHED
# bottle (whose root_url the formula now points at) — but don't use
# `brew uninstall`: in this fork `uninstall` cascades and also removes the
# formula's dependency kegs (while leaving their tabfiles), so the followup
# install won't restore them and `brew test` then fails "missing test
# dependencies". `brew reinstall` is no better here — it ignores the bottle
# block and rebuilds from source (poured_from_bottle=false). Removing only this
# formula's Cellar dir (keg + its tabfile) leaves deps' kegs intact and makes
# brew treat the formula as not-installed, so `install` pours the bottle.
KEG=$(cexec "$BREW_ENV brew --cellar $FORMULA")
cexec "rm -rf '$KEG'"
# Plain install, not --build-bottle: --build-bottle means "compile from
# source in a bottle-friendly configuration" and skips pouring an existing
# bottle outright, which defeats the entire point of this script (verified
# 2026-09-05: with --build-bottle here, this reinstall took the same ~3
# minutes as a real build and poured_from_bottle came back false).
#
# A keg-only formula whose bin/ overlaps another already-linked formula's
# names (e.g. llvm@21/lld@21 vs ohos-sdk's bundled clang/ld.lld/...) makes
# `brew install` exit nonzero here ("The `brew link` step did not complete
# successfully") even though the keg itself pours fine — this fork
# attempts (and reports conflicts on) linking a keg-only formula's bin/
# instead of skipping it outright. build.sh's own install tolerates this
# by accident (its 2-attempt retry loop's second attempt just finds the
# keg "already installed" and no-ops, since it doesn't remove the keg
# first) — this script removes the keg above specifically to force a
# fresh pour, so that accident doesn't apply and every install with real
# conflicts would otherwise hard-fail here every time. Confirmed
# 2026-09-05 on both llvm@21 and lld@21's own PRs. Don't let this
# link-only failure abort the script (`set -e` via lib.sh would); the
# poured_from_bottle check right below is the real signal for "did this
# actually work."
cbrew "install --verbose $TAP/$FORMULA" || true

POURED=$(cbrew "info --json=v2 $TAP/$FORMULA" | jq -r '.formulae[0].installed[0].poured_from_bottle')
echo "poured_from_bottle=$POURED"
[ "$POURED" = "true" ]

cbrew "test $FORMULA"
