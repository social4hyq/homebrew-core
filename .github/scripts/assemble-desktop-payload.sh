#!/usr/bin/env bash
# Assemble the HAP payload (resources/app) for the OHOS desktop shell.
#
# Layout (mirrors the packaged macOS app's resolution contract):
#   app/package.json                type:module, main: lib/main.js
#   app/lib/                        tsdown bundle outputs (main.js, preloads, welcome/)
#   app/dsh/desktop-runtime.json    runtime descriptor (shell reads release fields)
#   app/dsh/node_modules/@deepseek-ai/dsh-web-frontend/dist   renderer bundle
#   app/node_modules/               main bundle's external deps (production closure)
#
# Prereq: monorepo built (build:lib:host + bundle) and runtime assembled (prepare:dsh).

set -euo pipefail

MONOREPO="${1:?usage: assemble-hap-payload.sh <monorepo> <outdir>}"
OUT="${2:?outdir}"
TARGET="$MONOREPO/apps/desktop/.desktop-build/targets/openharmony-arm64"
RUNTIME_TREE="$TARGET/dsh"
WORK=/data/storage/el2/base/cache/dsh-hap-payload-work

[[ -f "$MONOREPO/apps/desktop/lib/main.js" ]] || { echo "desktop bundle missing; run bundle first" >&2; exit 1; }
[[ -d "$RUNTIME_TREE/node_modules" ]] || { echo "runtime tree missing: $RUNTIME_TREE" >&2; exit 1; }

rm -rf "$OUT/app"
mkdir -p "$OUT/app/lib" "$OUT/app/dsh"

# --- shell bundle ---
cd "$MONOREPO/apps/desktop/lib"
cp main.js command-manager-entry.js operation-report-worker.js "$OUT/app/lib/"
cp preload-*.cjs "$OUT/app/lib/"
cp -r welcome "$OUT/app/lib/"
cd - > /dev/null

# --- 清单（版本与上游 desktop 包一致） ---
python3 - "$OUT/app/package.json" <<'EOF'
import json, sys
src = json.load(open("/data/storage/el2/base/cache/dsh-desktop-analysis/monorepo/apps/desktop/package.json"))
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

# --- 主包外部依赖闭包（pnpm 生产安装） ---
rm -rf "$WORK" && mkdir -p "$WORK"
cat > "$WORK/package.json" <<'EOF'
{
  "name": "dsh-desktop-ohos-payload-deps",
  "private": true,
  "dependencies": {
    "electron-updater": "^6.8.9",
    "semver": "^7.8.5",
    "ws": "^8.21.3"
  }
}
EOF
# @deepseek-ai/* 是私有 workspace 包，用打包好的 tarball
P="$TARGET/packed"
cat > "$WORK/pnpm-workspace.yaml" <<EOF
overrides:
  '@deepseek-ai/cordis': 'file:$P/vendor/deepseek-ai-cordis-4.1.0.tgz'
  '@deepseek-ai/cosmokit': 'file:$P/vendor/deepseek-ai-cosmokit-1.9.0.tgz'
  '@deepseek-ai/schemastery': 'file:$P/vendor/deepseek-ai-schemastery-3.19.0.tgz'
  '@deepseek-ai/dsh-error': 'file:$P/dsh/deepseek-ai-dsh-error-0.2.2-rc.3.tgz'
  '@deepseek-ai/dsh-api-gateway': 'file:$P/dsh/deepseek-ai-dsh-api-gateway-0.2.2-rc.3.tgz'
EOF
python3 - <<'EOF'
import json
p = "/data/storage/el2/base/cache/dsh-hap-payload-work/package.json"
d = json.load(open(p))
d["dependencies"]["@deepseek-ai/cordis"] = "4.1.0"
d["dependencies"]["@deepseek-ai/dsh-error"] = "0.2.2-rc.3"
d["dependencies"]["@deepseek-ai/dsh-api-gateway"] = "0.2.2-rc.3"
json.dump(d, open(p, "w"), indent=2)
EOF
cd "$WORK"
npm_config_registry=https://registry.npmjs.org pnpm install --prod --ignore-scripts 2>&1 | tail -2
mkdir -p "$OUT/app/node_modules"
# 拍平 pnpm 双层布局：.pnpm/<pkg>/node_modules/<name> 全部 dereference 到顶层
#（直接 cp -L 顶层链接会让 cordis→cosmokit 这类传递依赖失去解析位置）。
for d in "$WORK/node_modules/.pnpm"/*/node_modules/*; do
  name=$(basename "$d")
  if [[ "$name" == @* ]]; then
    mkdir -p "$OUT/app/node_modules/$name"
    for sub in "$d"/*; do
      [[ -e "$OUT/app/node_modules/$name/$(basename "$sub")" ]] || cp -rL "$sub" "$OUT/app/node_modules/$name/"
    done
  else
    [[ -e "$OUT/app/node_modules/$name" ]] || cp -rL "$d" "$OUT/app/node_modules/"
  fi
done
echo "payload assembled at $OUT/app"
du -sh "$OUT/app"

# 启动探针入口（DSH_BOOTSTRAP=1 时启用，hilog 打 bootstrap 阶段标记）
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
if [[ "${DSH_BOOTSTRAP:-0}" == "1" ]]; then
  python3 -c "
import json
p = '$OUT/app/package.json'
d = json.load(open(p))
d['main'] = 'lib/bootstrap.mjs'
json.dump(d, open(p, 'w'), indent=2)"
  echo "bootstrap entry enabled"
fi
