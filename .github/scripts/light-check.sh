#!/bin/bash
# brew readall + brew audit (both blocking) over $CHANGED_JSON.
#
# Also flags (non-blocking) any changed formula whose name collides with a
# harmonybrew/core formula. `brew audit`'s own audit_name conflict check
# (formula_auditor.rb) only fires with `--strict` on the *core* tap itself
# (`return unless @core_tap`) — a third-party tap's plain `brew audit` never
# runs it, so a collision like this tap's zsh vs harmonybrew/core's
# same-named formula is invisible to upstream tooling. A collision isn't
# itself wrong (ours is a deliberate OHOS-specific alternate) — what it
# flags is the follow-up requirement: every reference to that name (docs,
# depends_on, install commands) must be tap-qualified (social4hyq/core/<name>),
# see README "命名与冲突约定". `homebrew/core/<name>` is the alias this brew
# build recognizes for its own core tap regardless of branding (verified:
# resolves even though `Formulary.factory(name).tap` reports "harmonybrew/core").
#
# The container's baked-in HOMEBREW_NO_INSTALL_FROM_API=1 (deliberate: audit/
# readall above should validate against this tap's own pinned Formula files,
# not an API cache that can drift) makes `brew info homebrew/core/<name>`
# silently fail to resolve — it falls through to FromTapLoader trying to load
# an uninstalled literal "homebrew/core" tap instead of ever reaching
# FromAPILoader, so the probe would never fire. `env -u` (not `=0`; any set
# value, even "0", still disables API loading — confirmed against this exact
# container) strips it for this one probe only, leaving audit/readall above
# unaffected.
source "$(dirname "$0")/lib.sh"

cbrew "readall $TAP"

FAIL=()
COLLIDE=()
for name in $(jq -r '.[]' <<< "$CHANGED_JSON"); do
  echo "== brew audit $name =="
  cbrew "audit --formula $TAP/$name" || FAIL+=("$name")

  if cexec "env -u HOMEBREW_NO_INSTALL_FROM_API $BREW_ENV brew info --json=v2 homebrew/core/$name" >/dev/null 2>&1; then
    COLLIDE+=("$name")
  fi
done

if [ "${#COLLIDE[@]}" -gt 0 ]; then
  echo "::warning::name collides with harmonybrew/core — qualify every reference as $TAP/<name>: ${COLLIDE[*]}"
  echo "- ⚠️ name collides with harmonybrew/core (qualify all references as \`$TAP/<name>\`): ${COLLIDE[*]}" >> "$GITHUB_STEP_SUMMARY"
fi

if [ "${#FAIL[@]}" -gt 0 ]; then
  echo "::error::brew audit failed: ${FAIL[*]}"
  echo "- ❌ audit failed: ${FAIL[*]}" >> "$GITHUB_STEP_SUMMARY"
  exit 1
fi
