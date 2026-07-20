#!/bin/bash
# Compare every atomgit release tag against the tag each formula's `bottle
# do` block (root_url) currently references; delete anything else that
# still matches a known formula's tag shape (<formula>-v<ver>-r<N>).
# Dry-run by default — pass DRY_RUN=false to actually delete.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

API=https://atomgit.com/api/v5/repos/social4hyq/homebrew-core
ag() { curl -sf -m 30 -H "Authorization: Bearer $ATOMGIT_TOKEN" "$@"; }

DRY_RUN="${DRY_RUN:-true}"

declare -A CURRENT_TAG
FORMULA_NAMES=()
while IFS= read -r f; do
  name=$(basename "$f" .rb)
  FORMULA_NAMES+=("$name")
  url=$(grep -oE 'root_url "[^"]+"' "$f" | head -1 | sed -E 's/root_url "(.+)"/\1/') || true
  [ -n "$url" ] && CURRENT_TAG["$name"]=$(basename "$url")
done < <(find Formula -name '*.rb' | sort)

# longest name first, so e.g. "bun-bootstrap" is tried before the "bun"
# prefix it contains — avoids misattributing a tag to the wrong formula
mapfile -t FORMULA_NAMES < <(printf '%s\n' "${FORMULA_NAMES[@]}" | awk '{ print length, $0 }' | sort -rn | cut -d' ' -f2-)

match_formula() {
  local tag="$1" f prefix rest
  for f in "${FORMULA_NAMES[@]}"; do
    prefix="${f}-v"
    if [[ "$tag" == "$prefix"* ]]; then
      rest="${tag#"$prefix"}"
      [[ "$rest" =~ -r[0-9]+$ ]] && { echo "$f"; return; }
    fi
  done
}

PAGE=1
TO_DELETE=()
while :; do
  TAGS_JSON=$(ag "$API/releases?per_page=100&page=$PAGE")
  COUNT=$(jq 'length' <<< "$TAGS_JSON")
  [ "$COUNT" -eq 0 ] && break

  while IFS= read -r tag; do
    formula=$(match_formula "$tag")
    [ -z "$formula" ] && continue
    current="${CURRENT_TAG[$formula]:-}"
    if [ -z "$current" ]; then
      echo "-- $tag: '$formula' has no current bottle block, skipping (removed formula? review manually)"
      continue
    fi
    [ "$tag" != "$current" ] && TO_DELETE+=("$tag")
  done < <(jq -r '.[].tag_name' <<< "$TAGS_JSON")

  [ "$COUNT" -lt 100 ] && break
  PAGE=$((PAGE + 1))
done

echo "### bottle-gc (DRY_RUN=$DRY_RUN)" >> "$GITHUB_STEP_SUMMARY"

if [ "${#TO_DELETE[@]}" -eq 0 ]; then
  echo "no orphaned bottle releases found" >> "$GITHUB_STEP_SUMMARY"
  exit 0
fi

echo "orphaned release(s): ${#TO_DELETE[@]}" >> "$GITHUB_STEP_SUMMARY"
for tag in "${TO_DELETE[@]}"; do
  echo "- \`$tag\`" >> "$GITHUB_STEP_SUMMARY"
done

if [ "$DRY_RUN" = "true" ]; then
  {
    echo ""
    echo "dry-run only — re-run via workflow_dispatch with dry_run=false to actually delete"
  } >> "$GITHUB_STEP_SUMMARY"
  exit 0
fi

for tag in "${TO_DELETE[@]}"; do
  echo "deleting atomgit tag $tag"
  ag -X DELETE "$API/tags/$tag" > /dev/null || echo "::warning::failed to delete atomgit tag $tag"
  # GitHub mirror release, best-effort (may not exist if the mirror upload
  # failed at publish time — see publish.sh's step 6)
  gh release delete "$tag" -R social4hyq/homebrew-core --yes --cleanup-tag 2>/dev/null \
    || echo "::notice::no GitHub mirror release for $tag (or already gone)"
done
echo "deleted ${#TO_DELETE[@]} orphaned release(s)" >> "$GITHUB_STEP_SUMMARY"
