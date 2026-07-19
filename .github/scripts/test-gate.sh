#!/bin/bash
# brew test gate: blocking when UPLOAD=true, warning otherwise.
source "$(dirname "$0")/lib.sh"

if cbrew "test $FORMULA"; then
  echo "brew test passed"
elif [ "$UPLOAD" = "true" ]; then
  echo "::error::brew test $FORMULA failed, refusing to publish. Fix the formula's test block first"
  exit 1
else
  echo "::warning::brew test $FORMULA failed (non-blocking with upload=false; blocks publishing)"
fi
