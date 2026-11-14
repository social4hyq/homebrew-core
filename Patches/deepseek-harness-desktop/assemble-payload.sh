#!/bin/sh
# Assemble the HAP payload (resources/app) for the OHOS desktop shell.
# Usage: assemble-payload.sh <monorepo-root> <outdir>
#
# Layout mirrors the packaged app's resolution contract:
#   app/package.json            type:module, main: lib/main.js
#   app/lib/                    tsdown bundle outputs
#   app/dsh/desktop-runtime.json + node_modules/@deepseek-ai/dsh-web-frontend/dist
#   app/node_modules/           main bundle's external production closure
set -eu

MONOREPO="${1:?usage: assemble-payload.sh <monorepo> <outdir>}"
OUT="${2:?outdir}"
TARGET="$MONOREPO/apps/desktop/.desktop-build/targets/openharmony-arm64"
RUNTIME_TREE="$TARGET/dsh"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/dsh-hap-payload-XXXXXX")
trap 'rm -rf "$WORK"' EXIT

[ -f "$MONOREPO/apps/desktop/lib/main.js" ] || { echo "desktop bundle missing; run bundle first" >&2; exit 1; }
[ -d "$RUNTIME_TREE/node_modules" ] || { echo "runtime tree missing: $RUNTIME_TREE" >&2; exit 1; }

rm -rf "$OUT/app"
mkdir -p "$OUT/app/lib" "$OUT/app/dsh"

# --- shell bundle ---
cd "$MONOREPO/apps/desktop/lib"
cp main.js command-manager-entry.js operation-report-worker.js "$OUT/app/lib/"
cp preload-*.cjs "$OUT/app/lib/"
cp -r welcome "$OUT/app/lib/"
cd - > /dev/null
cat > "$OUT/app/lib/bootstrap.mjs" <<'EOF'
console.log('DSH_SHELL_BOOT: stage 0 (entry)')
try {
  await import('electron')
  console.log('DSH_SHELL_BOOT: electron imported')
} catch (e) { console.log('DSH_SHELL_BOOT: electron import FAILED', String(e)) }
try {
  await import('./main.js')
  console.log('DSH_SHELL_BOOT: main.js loaded')
} catch (e) { console.log('DSH_SHELL_BOOT: main.js FAILED', String(e && e.stack || e)) }
EOF

# --- manifest ---
python3 - "$OUT/app/package.json" "$MONOREPO" <<'EOF'
import json, sys
src = json.load(open(sys.argv[2] + "/apps/desktop/package.json"))
out = {
    "name": "@deepseek-ai/dsh-desktop-ohos",
    "version": src["version"],
    "private": True,
    "type": "module",
    "main": "lib/main.js",
}
json.dump(out, open(sys.argv[1], "w"), indent=2)
EOF

# --- runtime descriptor + renderer dist ---
cp "$RUNTIME_TREE/desktop-runtime.json" "$OUT/app/dsh/"
mkdir -p "$OUT/app/dsh/node_modules/@deepseek-ai"
rm -rf "$OUT/app/dsh/node_modules/@deepseek-ai/dsh-web-frontend"
cp -r "$RUNTIME_TREE/node_modules/@deepseek-ai/dsh-web-frontend" "$OUT/app/dsh/node_modules/@deepseek-ai/"

# --- 主包外部依赖闭包（pnpm 生产安装 + 拍平） ---
P="$TARGET/packed"
cat > "$WORK/package.json" <<EOF
{
  "name": "dsh-desktop-ohos-payload-deps",
  "private": true,
  "dependencies": {
    "electron-updater": "^6.8.9",
    "semver": "^7.8.5",
    "ws": "^8.21.3",
    "@deepseek-ai/cordis": "4.1.0",
    "@deepseek-ai/dsh-error": "0.2.2-rc.3",
    "@deepseek-ai/dsh-api-gateway": "0.2.2-rc.3"
  }
}
EOF
cat > "$WORK/pnpm-workspace.yaml" <<EOF
overrides:
  '@deepseek-ai/cordis': 'file:$P/vendor/deepseek-ai-cordis-4.1.0.tgz'
  '@deepseek-ai/cosmokit': 'file:$P/vendor/deepseek-ai-cosmokit-1.9.0.tgz'
  '@deepseek-ai/schemastery': 'file:$P/vendor/deepseek-ai-schemastery-3.19.0.tgz'
  '@deepseek-ai/dsh-error': 'file:$P/dsh/deepseek-ai-dsh-error-0.2.2-rc.3.tgz'
  '@deepseek-ai/dsh-api-gateway': 'file:$P/dsh/deepseek-ai-dsh-api-gateway-0.2.2-rc.3.tgz'
EOF
cd "$WORK"
npm_config_registry=https://registry.npmjs.org pnpm install --prod --ignore-scripts > /dev/null
mkdir -p "$OUT/app/node_modules"
# 拍平 pnpm 双层布局（dereference；含传递依赖）
for d in "$WORK/node_modules/.pnpm"/*/node_modules/*; do
  name=$(basename "$d")
  if [ "${name#@}" != "$name" ]; then
    mkdir -p "$OUT/app/node_modules/$name"
    for sub in "$d"/*; do
      [ -e "$OUT/app/node_modules/$name/$(basename "$sub")" ] || cp -rL "$sub" "$OUT/app/node_modules/$name/"
    done
  else
    [ -e "$OUT/app/node_modules/$name" ] || cp -rL "$d" "$OUT/app/node_modules/"
  fi
done
echo "payload assembled at $OUT/app"
