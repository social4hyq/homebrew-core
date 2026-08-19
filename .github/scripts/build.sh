#!/bin/bash
# Source-build $FORMULA and verify the keg actually installed.
source "$(dirname "$0")/lib.sh"

# The ci-runner image bakes HOMEBREW_OHOS_BOTTLE_BINARY_SIGN=1 by default
# (most formulas want their poured binaries auto-signed), but prebuilt
# static ELF binaries segfault under that auto-sign pass (binary-sign-tool
# corrupts their ELF layout) — this first surfaced 2026-07-20/21 (PR #42,
# stuck on a `brew test` segfault, exit 139) on a prebuilt static ELF whose
# install() self-signs via ohos-bst-light: the CI-only auto-sign pass
# re-signed it a second time and broke it — confirmed by re-downloading +
# self-signing (once) the same artifact outside CI, which ran clean (see
# Formula/q/qemu-aarch64.rb).
# claude-code is a runtime-fetch stub (install() only writes a wrapper
# script, no ELF in the bottle at all — see Formula/c/claude-code.rb) so it
# has no odie guard and likely doesn't need this; included anyway since
# it's now autobump-allowlisted too and the unset is a harmless no-op if
# there's genuinely nothing for binary-sign-tool to touch.
# A from-source build is not automatically exempt from this list — what
# matters is the final ELF's shape, not how it got built. A CGO_ENABLED=0 Go
# build (or any other toolchain emitting a static ELF with no PT_INTERP/
# PT_DYNAMIC segment) hits the same corruption.
# zig@0.15 used to be on this list as a prebuilt static ELF, but
# binary-sign-tool signing it (single or double) was verified harmless on
# real hardware — the corruption mode is specific to bun and CGO_ENABLED=0
# Go outputs.
UNSET_SIGN_FORMULAS="claude-code qemu-aarch64"
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
#
# `brew update` also "updates" the social4hyq/core tap — which is THIS
# workspace, bind-mounted into the container, sitting at a detached HEAD on
# the PR branch tip (actions/checkout). Harmonybrew's tap update rebases that
# HEAD onto origin/main, leaving local-only ghost commits that were never
# pushed: the bottle write-back then landed on the ghost (2026-08-17..19,
# every opencode@2 PR build) and the publish push to the PR branch was
# rejected as non-fast-forward, then misreported as "force-pushed or
# polluted" by publish.sh's ancestry guard. Restore the checkout ref so the
# bottle commit fast-forwards the PR branch instead. Run as root inside the
# container: brew's rebase left root-owned git state on the bind mount.
CHECKOUT_SHA=$(git rev-parse HEAD)
cbrew "update --quiet" || echo "::warning::brew update failed; continuing with the image's baked index"
if [ "$(git rev-parse HEAD)" != "$CHECKOUT_SHA" ]; then
  echo "::warning::brew update rewrote the tap HEAD; resetting to checkout $CHECKOUT_SHA"
  cexec "git -C $TAP_IN_CONTAINER rebase --quit 2>/dev/null || true"
  cexec "git -C $TAP_IN_CONTAINER reset --hard $CHECKOUT_SHA"
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
