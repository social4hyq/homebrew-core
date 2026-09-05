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
# --build-bottle, not plain install: matches build.sh's own install flag.
# A keg-only formula whose bin/ overlaps another installed formula's names
# (e.g. llvm@21 vs ohos-sdk's bundled clang/llvm-*) hits benign "could not
# symlink, belongs to X" warnings either way, but plain `brew install`
# treats them as fatal (nonzero exit) while --build-bottle doesn't —
# confirmed 2026-09-05 on llvm@21's own PR (build.sh's --build-bottle
# install succeeded past this same warning in the same job; this line's
# plain install then failed on it during reinstall-from-published-bottle).
cbrew "install --build-bottle --verbose $TAP/$FORMULA"

POURED=$(cbrew "info --json=v2 $TAP/$FORMULA" | jq -r '.formulae[0].installed[0].poured_from_bottle')
echo "poured_from_bottle=$POURED"
[ "$POURED" = "true" ]

cbrew "test $FORMULA"
