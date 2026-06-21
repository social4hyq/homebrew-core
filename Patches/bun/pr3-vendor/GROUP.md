# pr3-vendor

**目标仓库**：vendor 上游（cloudflare/lolhtml + facebook/zstd）+ bun 自己（vendor patch 引用条件化）
**OHOS framing**：无（vendor patch 本身 OHOS-agnostic，bun 引用层做条件化）
**评估状态**：experiment (a) all-48-baseline PASS（evidence run #13）

## 分组目的

bun-src 通过 `patches/<vendor>/<file>.patch` 把 vendor 源码补丁应用到第三方 crate 上。本组包含两类：

1. **vendor 自身的 patch 文件**（cp 到 `<bun>/patches/<vendor>/`，由 ninja 当文件依赖应用）
2. **bun 侧引用条件化**（git apply 到 bun-src，让 vendor patch 仅在 OHOS 触发）

## Patch 清单

- patches/lolhtml/crate-type.patch
- patches/zstd/ohos-qsort-r.patch
- scripts/build/deps/zstd.ts.patch

