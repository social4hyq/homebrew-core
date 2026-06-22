# social4hyq/homebrew-core

HarmonyOS (OHOS aarch64) Homebrew tap。收录在鸿蒙系统上从源码构建的 formula 及其预编译 bottle，作为 [Harmonybrew](https://atomgit.com/Harmonybrew) 官方 core 的先行验证仓库。

## 仓库定位

最终目标是把本仓库中稳定下来的 formula 合入 [Harmonybrew 官方 core](https://atomgit.com/Harmonybrew)。当前仍未合入，原因有二：

1. **上游阻塞**：`bun` 与 `rust` 的官方 OHOS aarch64 版本尚未发布。本仓库自带的 `llvm@21` 工具链与 `bun-bootstrap` 预编译产物，是在上游缺失前提下的本机自举过渡方案。一旦 `bun` / `rust` 官方版发布，相关 formula 需要切换到上游产物，过渡层应当退出。
2. **验证范围有限**：现有 formula 在开发机上完成了构建、安装与基础 smoke 测试，但尚未在多样的 HarmonyOS 设备与版本上覆盖测试。稳定性需要更长时间观察才能确认。

在这两项前提解决之前，本仓库独立维护，不合入官方 core。

## Formulae

| Formula | 版本 | 说明 |
|---|---|---|
| `opencode` | 1.17.8 | OpenCode(AI 编码代理 CLI，bun compile 单文件 + 嵌入 Web UI) |
| `bun` | 1.3.14 | bun 稳定版 |
| `bun-canary` | 1.4.0-a4cd4d2 | bun canary 滚动版(`keg_only`) |
| `bun-bootstrap` | 1.4.0-a4cd4d2 | 预编译 bun，自举构建用 |
| `bun-webkit` | 6d586e293f | JavaScriptCore / WTF / bmalloc 静态库(bun 专用 WebKit fork) |
| `bun-pty` | 0.4.10 | `librust_pty.so`(portable-pty nix→0.31，源码构建 + 签名，`keg_only`) |
| `lightningcss` | 1.30.1 | `liblightningcss_node.so`(`keg_only`) |
| `tailwindcss-oxide` | 4.1.11 | `libtailwind_oxide.so`(`keg_only`) |
| `llvm@21` | 21.1.8 | OHOS 补丁版 clang + lld + multiarch runtime libs |
| `icu4c@78` | 78.3 | Unicode 库(用 llvm@21 重编，消除 stale ABI 标签) |

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
brew install bun           # JavaScript/TypeScript 运行时
brew install opencode      # AI 编码代理(自动拉入 bun 与全部 native 依赖)
```
