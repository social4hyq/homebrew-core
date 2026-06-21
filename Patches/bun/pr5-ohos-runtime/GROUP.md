# pr5-ohos-runtime

**目标仓库**：oven-sh/bun（OHOS-only runtime 实现）
**OHOS framing**：有（cfg gate + 替代实现）
**评估状态**：experiment (a) all-48-baseline PASS（evidence run #13）

## 分组目的

OHOS 上 syscall / 文件系统 / 进程模型 / 签名机制和 Linux 主线不同，bun 运行时需要替代实现：

- syscall：close_range / openat2 / epoll_pwait2 / memfd / fchmodat2 / pidfd 等 ENOSYS fallback
- 文件系统：linkat EPERM 多级 fallback、symlinkat 重试、tmpfile $TMPDIR 兼容、hmdfs getcwd 兜底
- 进程：vfork→fork + exit_group + CLOEXEC、PWD env、socket flag
- 签名：编译输出 / install 后 native 二进制走 binary-sign-tool
- 命名：process.platform / Bun.env.os 返 "ohos"

本组是 5 个 PR 中最大的（26 patches），合入上游需配合社区评审 OHOS 支持范围。

## Patch 清单

- src/bun_bin/lib.rs.patch
- src/bun_core/Global.rs.patch
- src/bun_core/env.rs.patch
- src/install/PackageInstall.rs.patch
- src/install/PackageInstaller.rs.patch
- src/install/PackageManager.rs.patch
- src/install/TarballStream.rs.patch
- src/install/isolated_install/Hardlinker.rs.patch
- src/install/lib.rs.patch
- src/install/lifecycle_script_runner.rs.patch
- src/install/npm.rs.patch
- src/jsc/bindings/bun-spawn.cpp.patch
- src/jsc/bindings/c-bindings.cpp.patch
- src/resolver/fs.rs.patch
- src/resolver/lib.rs.patch
- src/resolver/resolver.rs.patch
- src/runtime/api/bun/Terminal.rs.patch
- src/runtime/api/bun/spawn/stdio.rs.patch
- src/runtime/cli/build_command.rs.patch
- src/runtime/cli/filter_run.rs.patch
- src/runtime/cli/run_command.rs.patch
- src/spawn/process.rs.patch
- src/spawn_sys/spawn_process.rs.patch
- src/standalone_graph/StandaloneModuleGraph.rs.patch
- src/sys/lib.rs.patch
- src/sys/linux_syscall.rs.patch

## Alt 标注（备用拆分线）

下列 4 个 patch 同时具备 OHOS-specific + 跨平台 resolver robustness 性质，归 pr5 为主、pr2 为备用：

- src/resolver/fs.rs.patch（HOME/data fallback + EACCES robustness 两栖）
- src/resolver/lib.rs.patch
- src/resolver/resolver.rs.patch
- src/runtime/cli/run_command.rs.patch（PWD fallback + 权限错误 silentfail + root fallback）

后续若要拆出 pr2-resolver-robustness PR，从此 4 patch 起步。

## Followup

- **standalone-compile 已上线**: 2026-06-17 合入 `src/standalone_graph/StandaloneModuleGraph.rs.patch`，为 `bun build --compile` 添加 OHOS aarch64 支持（ELF SHT 解析 + COW/fsync 写保护）。TRAILER fallback 因 binary-sign-tool 不破坏 SHT 而故意省略，理由见 design §3（[设计文档](../../docs/superpowers/specs/2026-06-16-ohos-bun-standalone-compile-design.md)）。若签名工具未来版本破坏 SHT，需补 TRAILER scan fallback。
