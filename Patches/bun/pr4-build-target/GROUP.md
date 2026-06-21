# pr4-build-target

**目标仓库**：oven-sh/bun（build target enum + 交叉编译参数）
**OHOS framing**：有（"ohos" 作为 build target 一等公民）
**评估状态**：experiment (a) all-48-baseline PASS（evidence run #13）

## 分组目的

把 OHOS 加进 bun 的编译目标枚举体系（`Libc::Ohos`、`OS="ohos"`、`aarch64-unknown-linux-ohos` triple 等），让 `bun bd` / `bun build --compile` / `bun upgrade` 这条链能识别和处理 OHOS。

不含运行时（runtime）替代实现，只动 build pipeline 和 target metadata。

## Patch 清单

- package.json.patch
- scripts/build.ts.patch
- scripts/build/bun.ts.patch
- scripts/build/config.ts.patch
- scripts/build/deps/cares.ts.patch
- scripts/build/deps/mimalloc.ts.patch
- scripts/build/deps/webkit.ts.patch
- scripts/build/flags.ts.patch
- scripts/build/rust.ts.patch
- scripts/build/source.ts.patch
- scripts/build/tools.ts.patch
- scripts/utils.mjs.patch
- src/options_types/compile_target.rs.patch
- src/runtime/cli/upgrade_command.rs.patch

