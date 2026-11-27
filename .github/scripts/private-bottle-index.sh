#!/bin/bash
# Aggregate bottle artifacts from bottle-build(upload=false) into a private index.
# Consumes artifacts only; no network, no publish, no repo changes.
#
# Usage: private-bottle-index.sh --artifacts DIR --root-url URL --out DIR
#   DIR holds download-artifact output; each subdir is one artifact containing
#   <formula>-<ver>.*.bottle*.tar.gz and the matching .json from bottle.sh.
set -euo pipefail

ARTIFACTS=""
ROOT_URL=""
OUT=""
while (($#)); do
  case "$1" in
    --artifacts) ARTIFACTS="${2:?--artifacts needs a path}"; shift 2 ;;
    --root-url)  ROOT_URL="${2:?--root-url needs a URL}"; shift 2 ;;
    --out)       OUT="${2:?--out needs a path}"; shift 2 ;;
    *) printf 'private-bottle-index.sh: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

[[ -n "$ARTIFACTS" && -d "$ARTIFACTS" ]] || { echo "artifacts dir not found: $ARTIFACTS" >&2; exit 1; }
[[ -n "$ROOT_URL" ]] || { echo "--root-url is required" >&2; exit 2; }
[[ "$ROOT_URL" != *atomgit.com* ]] || { echo "refusing public atomgit root URL" >&2; exit 2; }
[[ -n "$OUT" ]] || { echo "--out is required" >&2; exit 2; }

mkdir -p "$OUT/bottles"
MANIFEST="$OUT/manifest.json"
count=0
: > "$MANIFEST.tmp"

# Collect all bottle tarballs and JSON files (artifacts may nest one level).
while IFS= read -r -d '' tarball; do
  base="$(basename "$tarball")"
  json="${tarball%.tar.gz}.json"
  # bottle.sh names the JSON after the tarball; rebuild variants use *.N.bottle.tar.gz.
  # Strip .tar.gz for the JSON name; fall back to any *.bottle.json in the same dir.
  if [[ ! -f "$json" ]]; then
    json="$(find "$(dirname "$tarball")" -maxdepth 1 -name '*.bottle*.json' -print -quit 2>/dev/null || true)"
  fi
  [[ -n "$json" && -f "$json" ]] || { echo "no bottle json for $base" >&2; exit 1; }

  # Each bottle JSON must declare a root_url under the private root (set by bottle.sh).
  json_root="$(jq -r '.. | objects | .root_url? // empty' "$json" 2>/dev/null | head -1 || true)"
  if [[ -n "$json_root" ]]; then
    [[ "$json_root" == "$ROOT_URL"* ]] || {
      echo "bottle json root_url ($json_root) does not match private root ($ROOT_URL)" >&2; exit 1;
    }
  else
    echo "warning: bottle json has no root_url field; cannot verify private root" >&2
  fi

  sha="$(sha256sum "$tarball" | awk '{print $1}')"
  cp "$tarball" "$OUT/bottles/$base"
  printf '{"bottle":"%s","sha256":"%s","root_url":"%s"}\n' \
    "$base" "$sha" "$ROOT_URL" >> "$MANIFEST.tmp"
  count=$((count + 1))
done < <(find "$ARTIFACTS" -type f -name '*.bottle*.tar.gz' -print0 2>/dev/null)

(( count > 0 )) || { echo "no bottle tarballs found under $ARTIFACTS" >&2; exit 1; }

printf '[' > "$MANIFEST"
sed -n '1h;1!H;${x;s/\n/,/g;p;}' "$MANIFEST.tmp" >> "$MANIFEST"
printf ']\n' >> "$MANIFEST"
rm -f "$MANIFEST.tmp"
echo "indexed $count bottle(s) into $OUT (root_url=$ROOT_URL)"
