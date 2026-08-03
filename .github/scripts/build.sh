#!/bin/bash
# Source-build $FORMULA and verify the keg actually installed.
source "$(dirname "$0")/lib.sh"

# The ci-runner image bakes HOMEBREW_OHOS_BOTTLE_BINARY_SIGN=1 by default
# (most formulas want their poured binaries auto-signed), but prebuilt
# static ELF binaries segfault under that auto-sign pass (binary-sign-tool
# corrupts their ELF layout). grok-build hit this 2026-07-20/21 (PR #42,
# stuck on a `brew test` segfault, exit 139): its install() self-signs the
# prebuilt static ELF via ohos-bst-light, then the CI-only auto-sign pass
# re-signed it a second time and broke it — confirmed by re-downloading +
# self-signing (once) the same 0.2.106 artifact outside CI, which ran
# clean (see Formula/g/grok-build.rb).
# claude-code is a runtime-fetch stub (install() only writes a wrapper
# script, no ELF in the bottle at all — see Formula/c/claude-code.rb) so it
# has no odie guard and likely doesn't need this; included anyway since
# it's now autobump-allowlisted too and the unset is a harmless no-op if
# there's genuinely nothing for binary-sign-tool to touch.
UNSET_SIGN_FORMULAS="claude-code grok-build cc-switch qemu-aarch64"
ENV_PREFIX=""
if tr ' ' '\n' <<< "$UNSET_SIGN_FORMULAS" | grep -qx "$FORMULA"; then
  ENV_PREFIX="env -u HOMEBREW_OHOS_BOTTLE_BINARY_SIGN "
fi

# The runner image bakes a Homebrew index, and the upstream harmonybrew CDN
# prunes bottles for superseded versions. A stale index therefore resolves a
# dependency to a file that is simply gone: cmake 4.3.4 (404) where 4.4.0_1 is
# what is actually published. That is not the transient 404 the retry below
# covers — it fails identically on every attempt — so refresh the index first.
# Non-fatal: if the refresh itself fails, the baked index may still be good
# enough, and the install below will say so.
cbrew "update --quiet" || echo "::warning::brew update failed; continuing with the image's baked index"

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
