#!/bin/bash
# Reinstall from the published bottle, verify poured_from_bottle, re-run brew test.
# A failure here means the published tag is bad: pull the release, fix, rerun.
source "$(dirname "$0")/lib.sh"

# formula content just changed; re-trust before reinstalling
cexec "brew trust $TAP"
cbrew "uninstall --ignore-dependencies $FORMULA || true"
cbrew "install --verbose $TAP/$FORMULA"

POURED=$(cbrew "info --json=v2 $TAP/$FORMULA" | jq -r '.formulae[0].installed[0].poured_from_bottle')
echo "poured_from_bottle=$POURED"
[ "$POURED" = "true" ]

cbrew "test $FORMULA"
