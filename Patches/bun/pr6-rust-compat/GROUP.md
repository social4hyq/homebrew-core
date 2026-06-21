# pr6-rust-compat

**目标仓库**：oven-sh/bun（与 OHOS 无关，是 Rust toolchain 兼容性修复）
**OHOS framing**：无（bun nightly Rust API 升级后所有平台都需要）
**评估状态**：experiment (a) all-48-baseline build PASS（evidence run #7 实证 `multi_array_list.rs` 必需）

## 分组目的

bun-src 当前 pin 的 Rust nightly toolchain（`nightly-2026-05-06`）有两类 API 变更影响本仓库：

1. **`Type::info().size: Option<u64>` → `Type::size() -> Option<u64>`**：消除中间 `info()` 结构体（`src/collections/multi_array_list.rs`）。
2. **`errno: i32` → `errno: i32` 但需 `unsigned_abs()` 转 `u32`**：shell builtin 比较 errno 时（`echo.rs` / `which.rs`）。

这些 patch 不带任何 OHOS framing，可直接作为 "bun nightly Rust compat" PR 推上游，预期审稿摩擦最小。

## Patch 清单

- src/collections/multi_array_list.rs.patch
- src/runtime/shell/builtin/echo.rs.patch
- src/runtime/shell/builtin/which.rs.patch

## Followup

- 若 bun 切换 stable Rust，这些 patch 可能整体废弃
- 提交上游前用最新 nightly 复测 API 状态
