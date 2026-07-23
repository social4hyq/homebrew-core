#!/bin/bash
# Source-build $FORMULA and verify the keg actually installed.
source "$(dirname "$0")/lib.sh"

# The ci-runner image bakes HOMEBREW_OHOS_BOTTLE_BINARY_SIGN=1 by default
# (most formulas want their poured binaries auto-signed), but opencode
# ships a prebuilt binary that segfaults under that auto-sign pass
# (binary-sign-tool corrupts its ELF layout) — it guards against this
# itself with an odie in install() (see Formula/o/opencode.rb), which is
# exactly what surfaced here: this is the first time its automated build
# path (bottle-build.yml, now reachable via pr-validate.yml's PR-branch
# build and via manual dispatch) ran without a human remembering to unset
# it by hand (2026-07-20, PR #35).
# claude-code is a runtime-fetch stub (install() only writes a wrapper
# script, no ELF in the bottle at all — see Formula/c/claude-code.rb) so it
# has no odie guard and likely doesn't need this; included anyway since
# it's now autobump-allowlisted too and the unset is a harmless no-op if
# there's genuinely nothing for binary-sign-tool to touch.
#
# grok-build hit the exact same corruption 2026-07-20/21 (PR #42, stuck on
# a `brew test` segfault, exit 139): its install() self-signs the prebuilt
# static ELF via ohos-bst-light, then the CI-only auto-sign pass re-signed
# it a second time and broke it — confirmed by re-downloading + self-signing
# (once) the same 0.2.106 artifact outside CI, which ran clean. Unlike
# opencode it had no odie guard yet (see Formula/g/grok-build.rb).
UNSET_SIGN_FORMULAS="opencode claude-code grok-build cc-switch"
ENV_PREFIX=""
if tr ' ' '\n' <<< "$UNSET_SIGN_FORMULAS" | grep -qx "$FORMULA"; then
  ENV_PREFIX="env -u HOMEBREW_OHOS_BOTTLE_BINARY_SIGN "
fi

# atomgit CDN has transient 404s: retry once after 90s; brew reuses partial work
for i in 1 2; do
  if cexec "${ENV_PREFIX}${BREW_ENV} brew install --build-bottle --verbose $TAP/$FORMULA" 2>&1 | tee build.log; then
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
