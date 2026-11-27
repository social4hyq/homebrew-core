#!/bin/bash
# 汇总 bottle-build(upload=false) 产出的多个 bottle artifact，建立私有 bottle 索引。
# 供下游 pour 验证使用。本脚本只消费 artifact，不联网、不发布、不改仓库。
#
# 用法：private-bottle-index.sh --artifacts DIR --root-url URL --out DIR
#   DIR 内是 actions/download-artifact 的产物：每个子目录是一个 artifact，
#   内含 <formula>-<ver>.*.bottle*.tar.gz 与同名 .json（bottle.sh 产出）。
set -euo pipefail

ARTIFACTS=""
ROOT_URL=""
OUT=""
while (($#)); do
  case "$1" in
    --artifacts) ARTIFACTS="${2:?--artifacts needs a path}"; shift 2 ;;
    --root-url)  ROOT_URL="${2:?--root-url needs a URL}"; shift 2 ;;
    --out)       OUT="${2:?--out needs a path}"; shift 2 ;;
    *) printf 'private-bottle-index.sh: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

[[ -n "$ARTIFACTS" && -d "$ARTIFACTS" ]] || { echo "artifacts dir not found: $ARTIFACTS" >&2; exit 1; }
[[ -n "$ROOT_URL" ]] || { echo "--root-url is required" >&2; exit 2; }
[[ "$ROOT_URL" != *atomgit.com* ]] || { echo "refusing public atomgit root URL" >&2; exit 2; }
[[ -n "$OUT" ]] || { echo "--out is required" >&2; exit 2; }

mkdir -p "$OUT/bottles"
MANIFEST="$OUT/manifest.json"
count=0
: > "$MANIFEST.tmp"

# 收集所有 bottle tarball + json（artifact 可能嵌套一层）。
while IFS= read -r -d '' tarball; do
  base="$(basename "$tarball")"
  json="${tarball%.tar.gz}.json"
  # bottle.sh 的 json 与 tarball 同名，但 rebuild 变体是 *.N.bottle.tar.gz，
  # 对应 json 名去掉 .tar.gz 即可；找不到时按通配找同目录 *.bottle.json。
  if [[ ! -f "$json" ]]; then
    json="$(find "$(dirname "$tarball")" -maxdepth 1 -name '*.bottle*.json' -print -quit 2>/dev/null || true)"
  fi
  [[ -n "$json" && -f "$json" ]] || { echo "no bottle json for $base" >&2; exit 1; }

  # JSON 必须声明 root_url 已指向私有地址（由 bottle.sh 的 PRIVATE_ROOT_URL 注入）。
  json_root="$(jq -r '.. | objects | .root_url? // empty' "$json" 2>/dev/null | head -1 || true)"
  if [[ -n "$json_root" ]]; then
    [[ "$json_root" == "$ROOT_URL"* ]] || {
      echo "bottle json root_url ($json_root) does not match private root ($ROOT_URL)" >&2; exit 1;
    }
  else
    echo "warning: bottle json has no root_url field; cannot verify private root" >&2
  fi

  sha="$(sha256sum "$tarball" | awk '{print $1}')"
  cp "$tarball" "$OUT/bottles/$base"
  printf '{"bottle":"%s","sha256":"%s","root_url":"%s"}\n' \
    "$base" "$sha" "$ROOT_URL" >> "$MANIFEST.tmp"
  count=$((count + 1))
done < <(find "$ARTIFACTS" -type f -name '*.bottle*.tar.gz' -print0 2>/dev/null)

(( count > 0 )) || { echo "no bottle tarballs found under $ARTIFACTS" >&2; exit 1; }

printf '[' > "$MANIFEST"
sed -n '1h;1!H;${x;s/\n/,/g;p;}' "$MANIFEST.tmp" >> "$MANIFEST"
printf ']\n' >> "$MANIFEST"
rm -f "$MANIFEST.tmp"
echo "indexed $count bottle(s) into $OUT (root_url=$ROOT_URL)"
