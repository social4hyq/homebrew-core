# social4hyq/homebrew-core

HarmonyOS（OHOS aarch64）的 Homebrew tap：收录尚未回流官方 [Harmonybrew/homebrew-core](https://atomgit.com/Harmonybrew/homebrew-core) 的 formula（Bun 自举链、AI CLI 等），稳定后合入上游。

> ⚠️ **早期阶段** — 仅在开发机做过构建 / 安装 / smoke 验证，未覆盖多机型多系统版本，不保证生产可用。

## 安装

```bash
brew tap social4hyq/core https://atomgit.com/social4hyq/homebrew-core.git
brew trust social4hyq/core         # Homebrew 6.0+ 必须显式信任第三方 tap

# 只装 bun：
brew install bun

# 装 opencode（上游源码构建的单体二进制，推荐）：
brew install opencode

# opencode v2 预览渠道（源码构建，命令名 opencode2，与 v1 并存）：
brew install opencode@2

# 或装预编译二进制路线的 opencode-shim（从 npmmirror 拉取官方 musl 单体二进制 + shim 适配）：
brew install opencode-shim

# 或装 v2 预编译二进制路线的 opencode-shim@2（命令名 opencode-shim2）：
brew install opencode-shim@2

# 只装 claude-code / grok-build / cc-switch（均从官方渠道拉取二进制 + 自签，依赖均已有 bottle）：
brew install claude-code
brew install grok-build
brew install cc-switch

# 装 qemu-aarch64（用户态 QEMU，strace 替代品 —— 鸿蒙 6.1 自签二进制无 ptrace 权限）：
brew install qemu-aarch64
```

装完跑一次 smoke：

```bash
bun --version && bun -e 'console.log(2**32, Math.PI)'
opencode --version
opencode2 --version
opencode-shim --version
opencode-shim2 --version
claude --version
grok --version
cc-switch --version
qemu-aarch64 --version && qemu-aarch64 -strace /bin/true
```

shell 补全随 bottle 装入，开箱即用。以生成式为主（`generate_completions_from_executable`，跟随二进制不漂移）：`opencode2` / `opencode-shim2` / `grok` / `cc-switch` 三 shell（bash/zsh/fish）齐全；`bun` 装源码树自带的静态三 shell 补全（同官方 formula）；`opencode` / `opencode-shim` 的上游生成器（yargs）只产 bash 脚本，故 bash 用生成的、zsh 另有手写补全（仅 `opencode`）、fish 无。

## Formulae

| Formula | 版本 | 定位 |
|---|---|---|
| `opencode` | 1.18.10, revision 2 | OpenCode AI 编码代理 CLI，**上游源码构建**（`bun build --compile` 单体二进制，compile target `bun-linux-arm64-ohos`）；原生依赖走 `@ohos-ports/*` npm 包。命令名 `opencode`（2026-08-01 前为 `ohos-opencode`） |
| `opencode@2` | 2.0.0-beta, revision 5 | opencode **v2 源码构建**预览路线（`bun build --compile` 单体二进制，compile target `bun-linux-arm64-ohos`）；v2 monorepo 重构后 CLI 包从 `packages/opencode` 移至 `packages/cli`，原生依赖精简至 `@ohos-ports/opentui-core` + `@ohos-ports/bun-pty`；命令名 `opencode2`，与 v1 并存（2026-08-01 前为 `ohos-opencode@2` / 命令 `ohos-opencode2`） |
| `opencode-shim` | 1.18.10, revision 1 | 同一 CLI 的**预编译 musl 二进制**路线（从 npmmirror 拉取 `opencode-linux-arm64-musl`）；注入 RUNPATH 补 Alpine libstdc++/libgcc，wrapper LD_PRELOAD `ohos-compat-shim` + `dlopen-sign-shim`；命令名 `opencode-shim`（2026-08-01 前为 `opencode`） |
| `opencode-shim@2` | 0.0.0-next-16650, revision 1 | opencode **v2 预览渠道**（`@opencode-ai/cli` 的 npm `next` dist-tag）的预编译二进制路线，处理方式与 `opencode-shim`(v1) 相同；命令名 `opencode-shim2`（2026-08-01 前为 `opencode@2` / 命令 `opencode2`） |
| `claude-code` | 2.1.220, revision 1 | Anthropic Claude Code CLI；**runtime-fetch stub**（Anthropic License 不允许重分发官方二进制），首次运行拉取 + 校验 sha256 + 自签 + 缓存 |
| `grok-build` | 0.2.118, revision 1 | xAI Grok Build CLI；完全静态 ELF，仅 `ohos-bst-light` self-sign，无需 shim/RUNPATH；bash/zsh/fish 补全 |
| `cc-switch` | 5.9.2, revision 2 | AI coding CLI 供应商切换器 + 本地代理（预编译静态 ELF，仅 `ohos-bst-light` self-sign）；主要用于给 codex 桥接 Chat-Completions-only provider（Kimi/DeepSeek 等） |
| ~~`codex`~~ | —（已下线 2026-07-23） | OpenAI Codex CLI。**已由 Harmonybrew 官方上游原生提供**，请直接 `brew install codex`（官方 core），本 tap 的自建 formula 已随之下线 |
| `qemu-aarch64` | 11.0.1-r0 | QEMU 用户态 aarch64 模拟器（Alpine 全静态 musl 构建）；鸿蒙 6.1 下自签二进制无 ptrace 权限、strace 不可用，`-strace` 纯用户态实现，是 syscall 跟踪的替代品（非虚拟机，syscall 仍下发鸿蒙内核） |
| `bun` | 1.4.0, revision 44 | Bun JavaScript runtime（`social4hyq/ohos-bun` 的 `ohos-aarch64` 分支）；`ohos-compat-shim` 已**静态内嵌**进可执行文件（覆盖 bun 及所有 `bun build --compile` 产物），无 LD_PRELOAD wrapper |
| `bun-bootstrap` | 1.4.0-5467a689, revision 1 | 预编译 bun，用来启动 `bun bd` 自举本机 bun；已预签，无需 ohos-sdk（`keg_only`） |
| `bun-webkit` | `5491700992`, revision 1 | JavaScriptCore / WTF / bmalloc 静态库，bun 专用 WebKit fork（`keg_only`） |
| `llvm@21` | 21.1.8, revision 4 | OHOS 补丁版 clang + lld + multiarch runtime libs；链接期 LLD `--code-sign` 签名（裁剪版，`keg_only`） |
| `icu4c@78` | 78.3, revision 2 | Unicode 库，用本仓库 llvm@21 重编以对齐 libc++ ABI（`keg_only`） |
| `ohos-bst-light` | 1.0.0, revision 1 | 轻量二进制自签工具，保留 ELF 结构不被破坏；预编译二进制 formula 的 self-sign 都靠它 |
| `ohos-compat-shim` | 0.2.4 | LD_PRELOAD 兼容垫片：拦截鸿蒙缺失/异常的 syscall（`close_range`/`fchmodat2`/`getpwuid_r`/`tmpfile`/`getcwd`/`linkat`/`symlinkat` 等）；`opencode-shim`/`claude-code` 共用 |
| `inject-runpath` | 0.2.0, revision 1 | 就地注入 DT_RUNPATH 到 ELF（零偏移移动），不破坏 Bun 编译产物的追加模块图；预编译二进制 formula（`opencode-shim`/`opencode-shim@2`）的 RUNPATH 注入靠它（`keg_only`） |
| `dlopen-sign-shim` | 0.1.0, revision 1 | LD_PRELOAD 垫片：`dlopen`/`dlmopen` 前自动 self-sign 未签名 ELF（运行时经 `$HOMEBREW_PREFIX` 解析 self-sign 路径），兜底运行时才解包落盘的原生模块 |

> 已下线：`close-range-shim`（2026-07-15，并入 `ohos-compat-shim`）；`bun-pty` / `lightningcss` / `tailwindcss-oxide`（2026-07-18，`ohos-opencode` 改走 `@ohos-ports/*` npm 包后 formula 失去存在意义）；`codex`（2026-07-23，改由 Harmonybrew 官方上游提供，见上表）。
>
> 改名（2026-08-01）：`opencode` → `opencode-shim`、`opencode@2` → `opencode-shim@2`（预编译 shim 路线）；`ohos-opencode` → `opencode`、`ohos-opencode@2` → `opencode@2`（源码构建路线，命令名同步改为 `opencode` / `opencode2`）。bottle 不随改名自动迁移，已装旧名的用户请先 `brew uninstall <旧名>` 再 `brew install <新名>`。

## Bottle

所有 bottle 面向 `arm64_ohos`，托管在 atomgit releases，tag 以各 formula 的 `root_url` 为准；`bun-bootstrap` 为预编译 binary pour。

## 已知限制

### 系统调用降级

`ohos-compat-shim` 以两种形态生效：`opencode-shim` / `opencode-shim@2` / `claude-code` 经 wrapper LD_PRELOAD 它；bun（r31+）把它静态内嵌进可执行文件，覆盖所有 `bun build --compile` 产物（含 `opencode` / `opencode2`）。使用者一般不用关心，极端场景下能感知到：

| 类别 | 鸿蒙缺什么 | 降级方式 | 用户能感知到的影响 |
|---|---|---|---|
| 部分 syscall | `close_range` / `openat2` / `epoll_pwait2` / `memfd` / `fchmodat2` / `pidfd` 返 `ENOSYS` | shim 拦截并退到老 syscall（`close` 循环 / `openat` + `O_PATH` / `epoll_pwait` 等） | 冷启动略慢，高并发 IO 吞吐低于 Linux 基线 |
| 文件系统 | `linkat` 跨 hmdfs 分区返 `EPERM`；`getcwd` 在 hmdfs 上偶发失败；`/tmp` 只读 | shim 提供 `linkat`/`symlinkat`/`getcwd` 兜底；临时文件走 `$TMPDIR` | 跨分区硬链接退化成复制；`$TMPDIR` 必须指向可写分区 |
| 进程模型 | `vfork` 在 OHOS 不可靠 | `vfork → fork` | spawn 比 Linux 略重，功能无差异 |
| 平台名 | npm 生态没有 OHOS 概念 | `process.platform === "openharmony"`，`bun install --os=openharmony` 可用 | 三方包若 hard-code `linux` 需手动映射 |

### 其他

- **签名按产物来源分四条路径**：bun 内置 `ohos_sign` crate（in-process，零 fork）；`llvm@21` 的 cc/c++ shim（LLD `--code-sign`，链接期）；预编译二进制（claude-code/grok-build/opencode-shim/opencode-shim@2/cc-switch/qemu-aarch64）用 `ohos-bst-light` self-sign；`opencode` / `opencode2` 的 `.codesign` 段由 bun compile 直接产生（bun 内置 `ohos_sign`）；运行时才解包的原生模块由 `dlopen-sign-shim` 兜底。
- `claude-code` 遵循 Anthropic License，不在 bottle 里重分发官方二进制：安装的是 runtime-fetch 包装脚本，首次运行下载、校验 sha256、自签并缓存。
- `opencode-shim` / `opencode-shim@2`（prebuilt）动态链接的 GCC 运行时（`libstdc++.so.6`/`libgcc_s.so.1`）OHOS 不自带，靠 Alpine musl 静态资源 + 就地 RUNPATH 注入解决。
- WebKit Inspector 走 socket 后端而非 glib 后端（OHOS 没有 GLib）。
- `icu4c@78` 用本仓库的 `llvm@21` 重编，让 ICU 的 libc++ 符号和 `bun` / `bun-webkit` 用同一个 mangling。
- bottle 只覆盖 `arm64_ohos`，不提供 macOS / x86_64 等其他平台产物。

## 核心能力确认

以下能力已在 HarmonyOS aarch64 上验证通过（bun 1.4.0）：

| 能力 | 状态 | 说明 |
|------|------|------|
| **JIT** (DFG + FTL) | JIT 三层全开 | `ENABLE_JIT=1`, `ENABLE_DFG_JIT=1`, `ENABLE_FTL_JIT=1`；`fib(25)×20` 14ms（解释器需 >800ms） |
| **Wasm JIT** (BBQ + OMG) | 已启用 | `ENABLE_WEBASSEMBLY_BBQJIT=1`, `ENABLE_WEBASSEMBLY_OMGJIT=1` |
| **NAPI** (node-gyp) | 100% 通过 | bun 自动配置 `CC=cc CXX=c++ LDFLAGS=-Wl,--code-sign`；需 `brew install llvm@21` |
| **Workspace 签名** | 已修复 | `bun install` 对 hoisted + isolated linker 的 `.node`/`.so` 均自动签名 |

## 上游

适配的长期目标是推回上游，消除 formula 层 workaround。当前 open：[lightningcss#1264](https://github.com/parcel-bundler/lightningcss/pull/1264)、[@tailwindcss/oxide#20276](https://github.com/tailwindlabs/tailwindcss/pull/20276)。合并并发布后，对应 `@ohos-ports/*` 包会 `npm deprecate`，`opencode` 的依赖 override 切回官方包。

## 反馈

遇到功能差异或崩溃，请附：HarmonyOS 版本、`bun --version`、复现命令、是否触及上面降级表里的类别。Bun / Rust 一旦发布官方 OHOS aarch64 版本，本仓库会优先切到上游产物，过渡 formula 简化或下线。
