#!/bin/bash
# Reinstall from the published bottle, verify poured_from_bottle, re-run brew test.
# A failure here means the published tag is bad: pull the release, fix, rerun.
source "$(dirname "$0")/lib.sh"

# formula content just changed; re-trust before reinstalling
cexec "brew trust $TAP"
# `brew reinstall` re-pours the formula from the published bottle (the
# bottle block in the formula now points at the just-pushed atomgit tag) while
# leaving its dependency kegs intact. The old uninstall+install pair cascaded
# dependency removal in this fork and the followup install didn't restore them,
# so `brew test` failed with "missing test dependencies" even though the bottle
# itself was good.
cbrew "reinstall --verbose $TAP/$FORMULA"

POURED=$(cbrew "info --json=v2 $TAP/$FORMULA" | jq -r '.formulae[0].installed[0].poured_from_bottle')
echo "poured_from_bottle=$POURED"
[ "$POURED" = "true" ]

cbrew "test $FORMULA"
