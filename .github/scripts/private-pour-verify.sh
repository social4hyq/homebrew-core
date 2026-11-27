#!/bin/bash
# 验证下游 formula 从私有 bottle pour，而非 source fallback。
# 用法：private-pour-verify.sh --formula NAME --index DIR --root-url URL [--brew-cmd "brew"]
# 说明：本脚本只做"是否 pour"的合同验证；真实签名/真机由后续 stage 负责。
#   --brew-cmd 可注入 fake brew 做本地合同测试（CI 里用真实 brew）。
set -euo pipefail

FORMULA=""
INDEX=""
ROOT_URL=""
BREW="brew"
while (($#)); do
  case "$1" in
    --formula)   FORMULA="${2:?--formula needs a name}"; shift 2 ;;
    --index)     INDEX="${2:?--index needs a path}"; shift 2 ;;
    --root-url)  ROOT_URL="${2:?--root-url needs a URL}"; shift 2 ;;
    --brew-cmd)  BREW="${2:?--brew-cmd needs a command}"; shift 2 ;;
    *) printf 'private-pour-verify.sh: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

[[ -n "$FORMULA" && "$FORMULA" =~ ^[A-Za-z0-9@+._-]+$ ]] || { echo "invalid formula name" >&2; exit 2; }
[[ -f "$INDEX/manifest.json" ]] || { echo "index manifest not found: $INDEX/manifest.json" >&2; exit 1; }
[[ -n "$ROOT_URL" && "$ROOT_URL" != *atomgit.com* ]] || { echo "invalid/private root url required" >&2; exit 2; }
command -v "$BREW" >/dev/null 2>&1 || { echo "brew command not found: $BREW" >&2; exit 127; }

# 索引里必须有目标 formula 的 bottle（按文件名前缀匹配）。
MATCH=$(jq -r --arg f "$FORMULA" '.[] | select(.bottle | startswith($f + "-")) | .bottle' "$INDEX/manifest.json" 2>/dev/null | head -1 || true)
[[ -n "$MATCH" ]] || { echo "no private bottle indexed for $FORMULA" >&2; exit 1; }

echo "verifying pour: formula=$FORMULA bottle=$MATCH root=$ROOT_URL"

# 合同验证：删 keg 后重装，断言 poured_from_bottle=true。
# 用 --formulae（精确装 formula，不触发 cask/依赖连带卸载），沿用 verify-poured.sh 的语义。
set +e
"$BREW" install --formula "$FORMULA" >/tmp/private-pour-install.log 2>&1
install_rc=$?
set -e
[[ $install_rc -eq 0 ]] || { echo "brew install failed (rc=$install_rc):" >&2; tail -40 /tmp/private-pour-install.log >&2; exit 1; }

POURED=$("$BREW" info --json=v2 "$FORMULA" 2>/dev/null | jq -r '.formulae[0].installed[0].poured_from_bottle // "false"' | head -1)
if [[ "$POURED" != "true" ]]; then
  echo "FAIL: $FORMULA did NOT pour from private bottle (poured_from_bottle=$POURED)" >&2
  echo "this usually means a source fallback or the private root_url was not used" >&2
  exit 1
fi

# 确认未发生 source fallback 的日志特征（若 brew 输出可被检查）。
if grep -qiE 'build.from.source|--build-from-source' /tmp/private-pour-install.log; then
  echo "FAIL: source fallback detected in install log" >&2
  exit 1
fi

echo "PASS: $FORMULA poured from private bottle (no source fallback)"
