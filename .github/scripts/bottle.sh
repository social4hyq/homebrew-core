#!/bin/bash
# Bottle the built keg. UPLOAD=true resolves the next atomgit release tag
# (<formula>-v<ver>-rN); UPLOAD=false uses a throwaway CI tag and fake root-url.
# Writes tag=<TAG> to $GITHUB_OUTPUT; bottle + json land in bottle-out/.
source "$(dirname "$0")/lib.sh"

API=https://atomgit.com/api/v5/repos/social4hyq/homebrew-core
ag() { curl -sf -m 30 -H "Authorization: Bearer $ATOMGIT_TOKEN" "$@"; }

VER=$(cbrew "info --json=v2 $TAP/$FORMULA" | jq -r '.formulae[0].versions.stable')
BASE="${FORMULA}-v${VER}"

if [ "$UPLOAD" = "true" ]; then
  # N = max existing + 1 across ALL pages. Any API failure aborts (curl -sf +
  # pipefail) instead of silently falling back to -r1, which would overwrite
  # old release assets.
  MAX=0
  PAGE=1
  while :; do
    TAGS=$(ag "$API/releases?per_page=100&page=$PAGE")
    NEW_MAX=$(echo "$TAGS" | jq -r '.[].tag_name' \
      | { grep -E "^${BASE}-r[0-9]+$" || true; } \
      | sed "s/^${BASE}-r//" | sort -n | tail -1)
    [ -n "$NEW_MAX" ] && [ "$NEW_MAX" -gt "$MAX" ] && MAX=$NEW_MAX
    [ "$(echo "$TAGS" | jq 'length')" -lt 100 ] && break
    PAGE=$((PAGE + 1))
  done
  TAG="${BASE}-r$(( MAX + 1 ))"
  # The computed tag must not exist; reuse would overwrite published bottles
  if ag "$API/releases/tags/$TAG" > /dev/null; then
    echo "::error::tag $TAG already exists, refusing to reuse (protects published bottles)"
    exit 1
  fi
  ROOT="https://atomgit.com/social4hyq/homebrew-core/releases/download/$TAG"
else
  TAG="${BASE}-ci${RUN_NUMBER}"
  ROOT="https://github.com/social4hyq/homebrew-core/releases/download/$TAG"
fi

echo "tag=$TAG" >> "$GITHUB_OUTPUT"
echo "== version=$VER tag=$TAG =="

docker exec -w /root "$CONTAINER" bash -lc \
  "$BREW_ENV brew bottle --json --root-url $ROOT $TAP/$FORMULA"
mkdir -p bottle-out
cexec "mv /root/*.bottle.tar.gz /root/*.bottle.json '$TAP_IN_CONTAINER/bottle-out/'"
ls -la bottle-out/
