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
# Harmonybrew silently rejects changed formulae (exit 0) without re-trust
cexec "brew trust $TAP"

# brew bottle --merge --write auto-commits the tap in-container as root
docker exec "$CONTAINER" git config --global --add safe.directory "$TAP_IN_CONTAINER"
docker exec "$CONTAINER" git config --global user.name "github-actions[bot]"
docker exec "$CONTAINER" git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
