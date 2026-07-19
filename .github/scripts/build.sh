#!/bin/bash
# Source-build $FORMULA and verify the keg actually installed.
source "$(dirname "$0")/lib.sh"

# atomgit CDN has transient 404s: retry once after 90s; brew reuses partial work
for i in 1 2; do
  if cbrew "install --build-bottle --verbose $TAP/$FORMULA" 2>&1 | tee build.log; then
    break
  fi
  [ "$i" = 2 ] && exit 1
  echo "::warning::brew install attempt $i failed, retrying in 90s (atomgit transient 404)"
  sleep 90
done

# trust rejections are silent (exit 0); verify the keg actually installed
N=$(cbrew "info --json=v2 $TAP/$FORMULA" | jq -r '.formulae[0].installed | length')
echo "installed_kegs=$N"
[ "$N" -ge 1 ] || { echo "::error::formula not installed (silent trust rejection? check trust/deps)"; exit 1; }
