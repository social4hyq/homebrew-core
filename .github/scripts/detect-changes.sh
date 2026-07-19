#!/bin/bash
# Classify formulae changed between $BEFORE and $AFTER into build / heavy /
# changed lists (JSON arrays written to $GITHUB_OUTPUT). Bottle-block-only
# changes are skipped; names in $HEAVY_FORMULAS get light checks only.
set -euo pipefail

if [[ "$BEFORE" =~ ^0+$ ]] || ! git cat-file -e "$BEFORE" 2>/dev/null; then
  echo "::warning::event.before unavailable (new branch/force push), comparing HEAD^..HEAD"
  BEFORE=$(git rev-parse "$AFTER^")
fi

strip_bottle() { sed '/^  bottle do$/,/^  end$/d'; }

mapfile -t FILES < <(git diff --name-status --no-renames "$BEFORE" "$AFTER" -- 'Formula/' \
  | awk '$1 != "D" && $2 ~ /^Formula\/[^\/]+\/[^\/]+\.rb$/ {print $2}')

BUILD=(); HEAVY=(); CHANGED=()
for f in "${FILES[@]}"; do
  name=$(basename "$f" .rb)
  [[ "$name" =~ ^[A-Za-z0-9@+._-]+$ ]] \
    || { echo "::error::invalid formula name: $name"; exit 1; }
  CHANGED+=("$name")
  # bottle-block-only changes don't need a rebuild
  if git cat-file -e "$BEFORE:$f" 2>/dev/null && \
     diff <(git show "$BEFORE:$f" | strip_bottle) \
          <(git show "$AFTER:$f"  | strip_bottle) >/dev/null; then
    echo "::notice::$name: bottle block only, skipping build"
    continue
  fi
  if tr ' ' '\n' <<< "$HEAVY_FORMULAS" | grep -qx "$name"; then
    HEAVY+=("$name")
  else
    BUILD+=("$name")
  fi
done

{
  echo "build=$(jq -cn '$ARGS.positional' --args "${BUILD[@]}")"
  echo "changed=$(jq -cn '$ARGS.positional' --args "${CHANGED[@]}")"
  echo "heavy=$(jq -cn '$ARGS.positional' --args "${HEAVY[@]}")"
} >> "$GITHUB_OUTPUT"

{
  echo "### auto-validate"
  echo "- build: ${BUILD[*]:-(none)}"
  echo "- heavy (light-check only): ${HEAVY[*]:-(none)}"
} >> "$GITHUB_STEP_SUMMARY"
