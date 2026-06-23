# social4hyq/homebrew-core

HarmonyOS (OHOS aarch64) Homebrew tap：收录在鸿蒙系统上从源码构建的 formula 及其预编译 bottle，作为 [Harmonybrew/homebrew-core](https://atomgit.com/Harmonybrew/homebrew-core) 的先行验证仓库。

> Harmonybrew/homebrew-core 是 Harmonybrew 项目的 core tap，绝大多数 formula 由上游 [Homebrew/homebrew-core](https://github.com/Homebrew/homebrew-core) 迁移而来。本仓库则负责孵化那些尚未具备迁移条件、需要在鸿蒙上从零打通自举链路的 formula，待稳定后再回流到官方 core。

> ⚠️ **早期实验版本** — 当前仓库内的 formula 处于"能跑通即发布"的探路阶段，**不保证生产可用**。继续阅读「当前状态与已知限制」了解风险。

## 仓库定位

最终目标是把本仓库中稳定下来的 formula 合入 [Harmonybrew/homebrew-core](https://atomgit.com/Harmonybrew/homebrew-core)。目前不合入官方 core，原因有三：

1. **Bun 上游正在迁移到 Rust 重写** — 官方 OHOS aarch64 二进制尚未发布；Bun 源码持续大改，本仓库的补丁集（`pr3-pr8`，~50 个 patch）需要频繁 rebase。官方 Rust 版发布之前，本仓库的 `bun` / `bun-bootstrap` / `bun-webkit` 三件套都属于过渡形态。
2. **HarmonyOS 系统调用面尚未对齐 Linux** — Bun 大量功能依赖底层 syscall，部分 syscall 在鸿蒙内核尚未开放或未实现；本仓库通过"功能降级 / 回退路径 / 软件模拟"绕过缺口，可能在功能完整性、性能与并发上偏离上游基准。
3. **验证范围有限** — formula 仅在开发机上完成构建、安装与 smoke 测试，未在多样的 HarmonyOS 设备与版本上覆盖测试。

在以上三项前提解决之前，本仓库独立维护。

## 当前状态与已知限制

### Bun 与 Rust 上游未对齐

- Bun 官方 Rust 重写未发布，C++ 主线频繁变动；`bun-src` patch（OHOS pr3-pr8）需要随上游 rebase
- Bun 自带 Rust 工具链当前用 nightly（`-Zbuild-std`），rust 官方未提供 OHOS aarch64 预编译 std；本机用 native bootstrap 方案过渡
- `bun-bootstrap` 是预编译的 L3 自举二进制（非可重现构建），仅用于驱动 `bun bd`；待 Bun 官方有原生 OHOS release 后退役

### 系统调用降级

下列 syscall 在鸿蒙内核当前版本未开放或未实现，本仓库通过 patch 在 Bun / 依赖侧降级处理，**可能影响功能与性能**：

| 类别 | 鸿蒙现状 | 本仓库处理 | 影响 |
|---|---|---|---|
| `pidfd_open` / `pidfd_send_signal` | 内核未开放 | 退化到 `kill(2) + waitpid` | 子进程信号竞态窗口扩大 |
| `io_uring` | 内核未实现 | 走传统 `epoll` + 线程池 | 高并发 IO 吞吐显著低于 Linux 基线 |
| `clone3` | 内核未实现 | 退化到 `clone(2)` 旧调用约定 | `Bun.spawn` 略慢，无功能差异 |
| 进程命名空间 / unshare | 部分 flag 不支持 | 直接跳过相关 fast-path | 沙箱隔离能力受限 |
| 应用沙箱 / SELinux | 容器侧已移除 | 二进制需先经 `binary-sign-tool` 自签 | 安装链路与 macOS/Linux 不同 |
| `fanotify` | 内核未实现 | 走 `inotify` | 文件监听粒度变粗 |

> 完整 syscall 降级清单维护在 `../Software/ohos-bun/docs/l4-bootstrap.md` 与 `ohos-patches/pr5-ohos-runtime/`。

### 其他限制

- WebKit Inspector 走 socket 后端而非 glib 后端（OHOS 无 GLib）；远程调试连接方式与上游略有差异
- `icu4c@78` 用本仓库的 `llvm@21` 重编，libc++ 符号落在 `__1` namespace，避免与 Bun/WebKit 的 stale ABI 标签冲突
- 所有 ELF 必须经 `ohos-sdk` 的 `binary-sign-tool` 自签后才能执行，formula 内已经处理；如二次打包请保留签名步骤
- bottle 仅覆盖 `arm64_ohos`，不提供 macOS / Linux x86_64 等其他平台产物

## Formulae

| Formula | 版本 | 说明 |
|---|---|---|
| `opencode` | 1.17.8 | OpenCode（AI 编码代理 CLI，bun compile 单文件 + 嵌入 Web UI） |
| `bun` | 1.4.0 | Bun 稳定版（L4 自举 + WebKit 静态链接） |
| `bun-canary` | 1.4.0-a4cd4d2 | Bun canary 滚动版（`keg_only`） |
| `bun-bootstrap` | 1.4.0-a4cd4d2 | 预编译 bun，自举构建用 |
| `bun-webkit` | 6d586e293f | JavaScriptCore / WTF / bmalloc 静态库（bun 专用 WebKit fork） |
| `bun-pty` | 0.4.10 | `librust_pty.so`（portable-pty nix→0.31，源码构建 + 签名，`keg_only`） |
| `lightningcss` | 1.30.1 | `liblightningcss_node.so`（`keg_only`） |
| `tailwindcss-oxide` | 4.1.11 | `libtailwind_oxide.so`（`keg_only`） |
| `llvm@21` | 21.1.8 | OHOS 补丁版 clang + lld + multiarch runtime libs |
| `icu4c@78` | 78.3 | Unicode 库（用 llvm@21 重编，消除 stale ABI 标签） |

## 依赖图

```
                          opencode 1.17.8
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
  bun ──────────────►  bun-pty, lightningcss,   llvm@21 (objcopy)
        │              tailwindcss-oxide         ohos-sdk (signing)
        │                       │                node, python@3.14
        │                       └──► rust, ohos-sdk
        │
        ├── bun-bootstrap       (过渡：预编译自举 bun)
        ├── bun-webkit          (JavaScriptCore 静态库)
        ├── llvm@21
        └── icu4c@78

  llvm@21 ──► ohos-sdk
```

## 安装

```bash
brew tap social4hyq/core https://github.com/social4hyq/homebrew-core.git
brew trust social4hyq/core         # Homebrew 6.0+ 要求显式信任第三方 tap
brew install bun                   # JavaScript/TypeScript 运行时
brew install opencode              # AI 编码代理（自动拉入 bun 与全部 native 依赖）
```

安装完成后建议跑一次基础 smoke：

```bash
bun --version && bun -e 'console.log(2**32, Math.PI)'
opencode --version
```

## 反馈与贡献

- 遇到功能差异或崩溃，请提供：HarmonyOS 版本、`bun --version`、复现命令、是否触及上面的降级 syscall 类别
- 上游 Bun / Rust 一旦发布 OHOS aarch64 官方版，本仓库会优先切换到上游产物并简化或下线过渡 formula
