# pr7-shared-cfg-gate

**目标仓库**：oven-sh/bun（共享 musl/OHOS 代码路径的 cfg gate 扩展）
**OHOS framing**：弱（仅扩门控，不引入 OHOS-only 实现）
**评估状态**：experiment (a) all-48-baseline smoke PASS（evidence run #8 实证 `recover.rs` + `napi_body.rs` 必需）

## 分组目的

bun-src 多处使用 `cfg(target_env = "musl")` 把 musl-specific 实现（如禁用 v8 符号、SIGALRM cast、crash_handler 路径）和 glibc 实现分开。

OHOS libc 也是 musl 派生，运行时行为对齐 musl 这一支，但 `target_env` 报作 `"ohos"`，导致原 `cfg(musl)` 块在 OHOS 下不编译，构建/smoke 直接挂掉：

- `recover.rs`：`cfg(musl)` SIGALRM 路径缺失 → musl 路径未编译 → 链接残留 v8 引用
- `napi_body.rs`：`cfg(musl)` v8 符号回避缺失 → smoke 重定位 fatal
- `crash_handler/lib.rs`：`cfg(musl)` crash_handler 块缺失 → 保守保留

每个 patch 把 `cfg(target_env = "musl")` 扩成 `cfg(any(target_env = "musl", target_env = "ohos"))`。

上游评审时可与 musl 维护者协作把规则统一为 "non-glibc"。

## Patch 清单

- src/crash_handler/lib.rs.patch
- src/runtime/napi/napi_body.rs.patch
- src/runtime/test_runner/harness/recover.rs.patch

## Followup

- 若上游接受 `cfg(any(target_env = "musl", target_env = "ohos"))`，PR 即可合并
- 若上游建议改用别的 cfg 谓词（如 `not(target_env = "gnu")` 等），需配合调整
