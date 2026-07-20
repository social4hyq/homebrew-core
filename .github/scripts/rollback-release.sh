#!/bin/bash
# Best-effort deletion of the atomgit release $TAG after a publish failure
# that happened BEFORE the bottle commit reached main (never call this after
# a successful push: main would then reference a deleted release).
source "$(dirname "$0")/lib.sh"

[ -n "${TAG:-}" ] || { echo "no tag resolved, nothing to roll back"; exit 0; }

API=https://atomgit.com/api/v5/repos/social4hyq/homebrew-core
ag() { curl -sf -m 30 -H "Authorization: Bearer $ATOMGIT_TOKEN" "$@"; }

if ! ag "$API/releases/tags/$TAG" > /dev/null; then
  echo "release $TAG does not exist, nothing to roll back"
  exit 0
fi

# atomgit has no standalone "delete release" endpoint (DELETE on both
# /releases/tags/{tag} and /releases/{id} returns 405; also absent from the
# official API reference). Deleting the underlying git tag cascades instead:
# real-machine test 2026-07-20 confirmed DELETE /tags/{tag_name} removes both
# the tag and its release — including an already-uploaded attach-type asset
# — in one call, with GET /releases/tags/{tag} 404ing immediately after (no
# polling needed).
if ! ag -X DELETE "$API/tags/$TAG" > /dev/null; then
  echo "::error::could not delete tag $TAG — remove it manually before re-running"
  echo "- ❌ failed publish left release $TAG behind; delete it manually" >> "$GITHUB_STEP_SUMMARY"
  exit 1
fi

if ag "$API/releases/tags/$TAG" > /dev/null; then
  echo "::error::tag $TAG deleted but release still visible — remove it manually before re-running"
  echo "- ❌ failed publish left release $TAG behind; delete it manually" >> "$GITHUB_STEP_SUMMARY"
  exit 1
fi

echo "release $TAG deleted"
echo "- 🧹 rolled back release $TAG after failed publish" >> "$GITHUB_STEP_SUMMARY"
