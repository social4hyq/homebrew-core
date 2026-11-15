#!/bin/bash
# Upload the desktop payload tarballs to an atomgit release.
#
#   publish-desktop-payloads.sh <version> <asset...>
#
# Mirrors .github/scripts/publish.sh (presigned OBS URL + PUT): the runner
# downloads payloads from atomgit in seconds, while same-size GitHub release
# assets stalled for minutes through the proxy.
set -euo pipefail

: "${ATOMGIT_TOKEN:?ATOMGIT_TOKEN is required}"
VERSION="${1:?usage: publish-desktop-payloads.sh <version> <asset...>}"
shift
API=https://atomgit.com/api/v5/repos/social4hyq/homebrew-core
TAG="deepseek-harness-desktop-v$VERSION"

ag() { curl -sS --fail-with-body -m 30 --retry 3 --retry-delay 5 --retry-connrefused -H "Authorization: Bearer $ATOMGIT_TOKEN" "$@"; }

if ! ag "$API/releases/tags/$TAG" > /dev/null 2>&1; then
  ag -X POST -H "Content-Type: application/json" \
    -d "$(jq -n --arg tag "$TAG" --arg body "Prebuilt desktop payloads (shell + host runtime)" \
          '{tag_name: $tag, name: $tag, target_commitish: "main", body: $body}')" \
    "$API/releases" > /dev/null
fi

for asset in "$@"; do
  name=$(basename "$asset")
  resp=$(ag "$API/releases/$TAG/upload_url?file_name=$name")
  echo "uploading $name"
  curl -sS --fail-with-body --tcp-nodelay -H "Expect:" \
    --speed-limit 1024 --speed-time 120 -m 3600 -X PUT "$(echo "$resp" | jq -r .url)" \
    -H "x-obs-meta-project-id: $(echo "$resp" | jq -r '.headers["x-obs-meta-project-id"]')" \
    -H "x-obs-acl: $(echo "$resp" | jq -r '.headers["x-obs-acl"]')" \
    -H "x-obs-callback: $(echo "$resp" | jq -r '.headers["x-obs-callback"]')" \
    -H "Content-Type: application/octet-stream" \
    --data-binary "@$asset" -w "\nHTTP=%{http_code}\n" | tail -1
done
