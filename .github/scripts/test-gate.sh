#!/bin/bash
# brew test gate: blocking when UPLOAD=true, warning otherwise.
source "$(dirname "$0")/lib.sh"

# `timeout` around the docker exec itself (not just cbrew's inner command):
# a formula's test binary hanging (observed 2026-07-20, grok-build 0.2.106 —
# `grok --version` never returned inside brew's own Mktemp test sandbox, no
# root cause confirmed) would otherwise stall this step for the whole job
# timeout instead of failing fast with a diagnosable message.
if timeout 180 docker exec "$CONTAINER" bash -lc "$BREW_ENV brew test $FORMULA"; then
  echo "brew test passed"
elif [ "$UPLOAD" = "true" ]; then
  echo "::error::brew test $FORMULA failed or timed out after 180s, refusing to publish. Fix the formula's test block first"
  exit 1
else
  echo "::warning::brew test $FORMULA failed or timed out after 180s (non-blocking with upload=false; blocks publishing)"
fi
