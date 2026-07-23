#!/bin/bash
# Start the OHOS container and apply one-time config.
source "$(dirname "$0")/lib.sh"

docker pull "$IMAGE"
# seccomp=unconfined: default docker profile blocks io_uring_setup, killing bun
docker run -d --name "$CONTAINER" --init \
  --security-opt seccomp=unconfined \
  -v "$GITHUB_WORKSPACE:$TAP_IN_CONTAINER" \
  "$IMAGE" sleep infinity

# musl tmpfile() hardcoded path + /system/bin/sh + /system/lib/ld-musl
# (bottle ELFs' PT_INTERP targets the real-device path)
cexec 'mkdir -p /data/local/tmp /system/bin /system/lib &&
  ln -sf /bin/sh /system/bin/sh &&
  ln -sf /lib/ld-musl-aarch64.so.1 /system/lib/ld-musl-aarch64.so.1'

# cargo sparse protocol straight to crates.io (git protocol too slow on Azure)
cexec 'mkdir -p /root/.cargo && printf "[registries.crates-io]\nprotocol = \"sparse\"\n\n[net]\ngit-fetch-with-cli = true\nretry = 3\n" > /root/.cargo/config.toml'

cexec 'brew --version && brew tap'

# Needed for `brew bump-formula-pr` (autobump.yml): without a brew-installed
# git, Homebrew's superenv git shim falls into a `whence -a git` fallback
# loop with known bugs (broken stdin — see git commit history). With it,
# the shim's fast path execs $HOMEBREW_PREFIX/bin/git directly.
cexec 'brew install git'

# brew bottle --merge --write auto-commits the tap in-container as root
docker exec "$CONTAINER" git config --global --add safe.directory "$TAP_IN_CONTAINER"
docker exec "$CONTAINER" git config --global user.name "github-actions[bot]"
docker exec "$CONTAINER" git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"

# `brew bump-formula-pr` resolves the tap's remote via Homebrew's own
# GitRepository#origin_url, which calls git with GIT_CONFIG_GLOBAL=/dev/null
# (Utils::Git.no_global_config_env — avoids the user's personal git config
# leaking into brew's internal queries). That env var blanks out the ENTIRE
# global config file, including the safe.directory exception registered
# above two lines up, so git re-detects "dubious ownership" on this
# bind-mounted directory (owned by the host runner's UID, not root) and
# every brew-internal git query on the tap silently returns nil — which is
# what actually caused "does not have a remote repository!" (2026-07-20,
# many hours of debugging). GIT_CONFIG_SYSTEM is NOT blanked by that
# mechanism, so registering the same exception at the system level survives
# it. Must use the brew-installed git specifically (not /usr/bin/git) since
# that's the binary Utils::Git.git shim execs and each git version may
# resolve --system to a different default path.
docker exec "$CONTAINER" bash -lc \
  "\$($BREW_ENV brew --prefix)/bin/git config --system --add safe.directory $TAP_IN_CONTAINER"

# Also needed by bump-formula-pr (Homebrew::Bump.create_pr): it resolves the
# tap's default branch via `git symbolic-ref refs/remotes/origin/HEAD`, which
# actions/checkout never sets up (it checks out a specific sha, not a full
# clone) — without it, bump-formula-pr dies with "does not have a default
# branch!". Writing the symref directly (not `git remote set-head`, which
# additionally requires refs/remotes/origin/main to already resolve locally
# — not true for a shallow, non-fetch-depth-0 checkout like autobump.yml's,
# confirmed 2026-07-20) needs no network round-trip and no pre-existing ref,
# since we already know the branch is main. `|| true`: only autobump.yml's
# bump-formula-pr flow needs this; a failure here must never break
# setup-container.sh for the other workflows that share it.
docker exec "$CONTAINER" bash -lc \
  "cd $TAP_IN_CONTAINER && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main" \
  || true

# A third bump-formula-pr blocker (2026-07-20): actions/checkout embeds its
# own ephemeral, limited-permission token as a git http.extraheader on the
# checkout — bump-formula-pr's own `git push` picks that up ahead of
# HOMEBREW_GITHUB_API_TOKEN and gets 403'd as github-actions[bot] (denied
# push access), instead of using the admin BOT_PUSH_TOKEN passed in via env.
# Same fix publish.sh already uses for its own push: drop the extraheader so
# nothing shadows the token Homebrew is actually given. `|| true`: harmless
# no-op for every other workflow that doesn't push from here.
docker exec "$CONTAINER" bash -lc \
  "cd $TAP_IN_CONTAINER && git config --unset-all http.https://github.com/.extraheader" \
  || true

# Harmonybrew silently rejects changed formulae (exit 0) without re-trust.
# MUST run last, after every git-config fix above: `brew trust` persists the
# tap's *current* Tap#reference (which for a custom (non-atomgit) remote IS
# tap.remote, i.e. GitRepository#origin_url — the exact call the
# safe.directory/GIT_CONFIG_GLOBAL dance above fixes). Trusting before that
# fix landed stored a stale fallback reference (name-based, computed while
# tap.remote still resolved nil), which the code path for any formula NOT
# named literally on the command line (Trust.explicitly_allowed? checks
# ARGV — dependencies loaded transitively never appear there) then failed to
# match against the tap's now-correctly-resolved custom-remote identity:
# "Refusing to load formula ... from untrusted tap" for opencode's dependency
# ohos-bst-light, even though opencode itself (named directly in `brew install
# opencode`) loaded fine. Confirmed 2026-07-20 via PR #35: reordering this to
# run after the git fixes resolves it — pure ordering bug, not a new
# mechanism.
cexec "brew trust $TAP"
