#!/usr/bin/env bash
# Build the DeepSeek Harness desktop payloads inside the OHOS CI container.
#
#   build-desktop-payloads.sh <upstream-ref>
#
# Produces (in $GITHUB_WORKSPACE/out):
#   dsh-desktop-runtime-<version>-<sha8>.tar.gz
#   dsh-desktop-shell-<version>-<sha8>.tar.gz
#
# The patch set lives in .github/desktop-patches (deliberately outside Patches/
# so the unused-patches bot never flags it). The container is the ci-runner
# image: brew provides node/node@24/pnpm/cmake/git/ripgrep/ohos-selfsign.

set -euo pipefail

REF="${1:?usage: build-desktop-payloads.sh <upstream-ref>}"
TAP="${GITHUB_WORKSPACE:?GITHUB_WORKSPACE is required}"
WORK="${WORK_DIR:-/storage/Users/currentUser/.tmp/dsh-payload-work}"
OUT="$TAP/out"
CACHE="${DSH_PAYLOAD_CACHE:-/cache}"
STORE="$CACHE/pnpm-store"
NODE24="$(brew --prefix node@24)/bin/node"

log() { printf '\n=== %s ===\n' "$*"; }

log "source $REF"
rm -rf "$WORK"
mkdir -p "$WORK"
curl -sL --retry 10 --retry-all-errors --retry-delay 3 \
  -o "$WORK/src.tar.gz" "https://github.com/deepseek-ai/deepseek-harness/archive/${REF}.tar.gz"
tar xzf "$WORK/src.tar.gz" -C "$WORK"
mv "$WORK"/deepseek-harness-* "$WORK/monorepo"
M="$WORK/monorepo"
cd "$M"

log "apply OHOS patch set"
for p in "$TAP"/.github/desktop-patches/000*.patch; do
  patch -p1 -l < "$p" > /dev/null
  echo "applied $(basename "$p")"
done

VERSION=$(python3 -c "import json;print(json.load(open('apps/desktop/package.json'))['version'])")
TARGET="$M/apps/desktop/.desktop-build/targets/openharmony-arm64"
mkdir -p "$OUT" "$STORE"

export ELECTRON_SKIP_BINARY_DOWNLOAD=1
export DSH_DESKTOP_TARGET_PLATFORM=openharmony
export DSH_DESKTOP_NODE="$NODE24"
export DSH_OHOS_NODE_BINARY="$NODE24"
export DSH_SIGN_TOOL="$(brew --prefix ohos-selfsign)/bin/selfsign"
export DSH_SIGN_TOOL_MODE=inplace
export npm_config_store_dir="$STORE"
export npm_config_fetch_retries=10
export npm_config_fetch_timeout=300000
export npm_config_network_concurrency=8

log "pnpm install"
pnpm install --frozen-lockfile --reporter=append-only 2>&1 | tail -2

log "client build record"
pnpm exec tsx -e '
  import { writeClientBuildRecord, repositoryClientBuildEnvironment, resolveClientBuildEnvironment } from "./scripts/client-build-environment.ts"
  const env = resolveClientBuildEnvironment(repositoryClientBuildEnvironment(process.cwd(), process.env), "local")
  writeClientBuildRecord(process.cwd(), env)
'

log "host + client + web builds"
pnpm run build:lib:host
pnpm run build:lib:client
pnpm run build:web

log "pack"
pnpm exec tsx apps/desktop/scripts/pack-local-packages.ts --out "$TARGET/packed/dsh"
pnpm --dir apps/desktop-host pack --pack-destination "$TARGET/packed/dsh"
pnpm run release:pack --family vendor --out "$TARGET/packed/vendor"
mkdir -p "$TARGET/packed/landlock"
pnpm --dir native/system run build:ts
pnpm --dir native/system/packages/entry pack --pack-destination "$TARGET/packed/landlock"

log "OHOS native packages"
NATIVES="$WORK/natives"
mkdir -p "$NATIVES"
NARB_COMMIT=a58d3599a2e551d7d706d1ff796c9fd4bbaff63c
curl -sL --retry 10 --retry-all-errors -o "$WORK/narb.tar.gz" \
  "https://github.com/deepseek-ai/dsh-node-addon-require-builtin/archive/${NARB_COMMIT}.tar.gz"
mkdir -p "$WORK/narb" && tar xzf "$WORK/narb.tar.gz" -C "$WORK/narb" --strip-components=1
RB="$NATIVES/node-addon-require-builtin-openharmony-arm64"
mkdir -p "$RB/prebuilt"
cat > "$RB/index.js" <<'EOF'
'use strict';
const { loadPrebuild } = require('node-addon-native-custom-loader');
module.exports = loadPrebuild(__dirname);
EOF
cat > "$RB/package.json" <<'EOF'
{
  "name": "node-addon-require-builtin-openharmony-arm64",
  "version": "0.1.9",
  "main": "./index.js",
  "os": ["openharmony"],
  "cpu": ["arm64"],
  "engines": { "node": ">=20" },
  "files": ["index.js", "prebuilds.json", "prebuilt/"],
  "dependencies": { "node-addon-native-custom-loader": "0.1.9" },
  "license": "MIT"
}
EOF
cat > "$RB/prebuilds.json" <<'EOF'
{
  "platform": "openharmony-arm64",
  "binaries": [
    { "backend": "napi", "abi": "napi-v9", "binaryTag": "napi-v9", "node": ">=20",
      "path": "prebuilt/openharmony-arm64-napi-v9.node" }
  ]
}
EOF
( cd "$WORK/narb/packages/native" \
  && npm install --no-save --no-audit --no-fund node-addon-api@8 > /dev/null \
  && npx --yes node-gyp@11 rebuild -- -Dnarb_product=require-builtin > /dev/null )
cp "$WORK/narb/packages/native/build/Release/require_builtin.node" \
   "$RB/prebuilt/openharmony-arm64-napi-v9.node"
"$DSH_SIGN_TOOL" "$RB/prebuilt/openharmony-arm64-napi-v9.node" > /dev/null
mkdir -p "$RB/node_modules"
cp -r "$M/node_modules/.pnpm/node-addon-native-custom-loader@0.1.9/node_modules/node-addon-native-custom-loader" \
      "$RB/node_modules/"
for spec in "@img/sharp-wasm32" "@emnapi/runtime" "tslib"; do
  dir="$WORK/npm-$(echo "$spec" | tr '/@' '--')"
  mkdir -p "$dir"
  npm pack --silent --pack-destination "$WORK" "$spec" > /dev/null
  tar xzf "$WORK/$(ls -t "$WORK"/*.tgz | head -1)" -C "$dir" --strip-components=1
  target="$NATIVES/$spec"
  mkdir -p "$(dirname "$target")"
  cp -r "$dir" "$target"
done
export DSH_OHOS_NATIVE_PACKAGES="$NATIVES/node-addon-require-builtin-openharmony-arm64:$NATIVES/@img/sharp-wasm32:$NATIVES/@emnapi/runtime:$NATIVES/tslib"

log "runtime assembly"
pnpm --dir apps/desktop run prepare:runtime
pnpm --dir apps/desktop run prepare:packages
pnpm --dir apps/desktop run prepare:dsh -- --defer-runtime-smoke

log "shell payload"
bash "$TAP/.github/scripts/assemble-desktop-payload.sh" "$M" "$WORK/hap"

log "tarballs"
STAGE="$WORK/stage"
rm -rf "$STAGE" && mkdir -p "$STAGE/runtime"
cp -a "$TARGET/dsh" "$STAGE/runtime/dsh"
cp -a "$TARGET/runtime/primary-runtime" "$STAGE/runtime/primary-runtime"
cp -a "$TARGET/runtime/bin" "$STAGE/runtime/bin"
cp -a "$TARGET/runtime/cli" "$STAGE/runtime/cli"
cp -a "$TARGET/runtime/versions.json" "$STAGE/runtime/versions.json"
cp -a "$WORK/hap/app" "$STAGE/app"

( cd "$STAGE" && tar czf "$WORK/runtime.tar.gz" runtime && tar czf "$WORK/shell.tar.gz" app )
RSHA=$(sha256sum "$WORK/runtime.tar.gz" | cut -d' ' -f1)
SSHA=$(sha256sum "$WORK/shell.tar.gz" | cut -d' ' -f1)
mv "$WORK/runtime.tar.gz" "$OUT/dsh-desktop-runtime-$VERSION-${RSHA:0:8}.tar.gz"
mv "$WORK/shell.tar.gz" "$OUT/dsh-desktop-shell-$VERSION-${SSHA:0:8}.tar.gz"

cat > "$OUT/payload-provenance.json" <<JSON
{
  "upstream_ref": "$REF",
  "version": "$VERSION",
  "tap_commit": "${GITHUB_SHA:-local}",
  "patch_set": "$(sha256sum "$TAP"/.github/desktop-patches/000*.patch | sha256sum | cut -d' ' -f1)",
  "node": "$("$NODE24" --version)",
  "pnpm": "$(pnpm --version)",
  "sharp_wasm32": "0.35.5",
  "emnapi_runtime": "1.11.3",
  "tslib": "2.8.1",
  "require_builtin_commit": "$NARB_COMMIT",
  "shell_sha256": "$SSHA",
  "runtime_sha256": "$RSHA"
}
JSON

{
  echo "VERSION=$VERSION"
  echo "RUNTIME_ASSET=dsh-desktop-runtime-$VERSION-${RSHA:0:8}.tar.gz"
  echo "RUNTIME_SHA=$RSHA"
  echo "SHELL_ASSET=dsh-desktop-shell-$VERSION-${SSHA:0:8}.tar.gz"
  echo "SHELL_SHA=$SSHA"
} | tee "$OUT/manifest.env"
