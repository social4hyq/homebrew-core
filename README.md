# social4hyq/homebrew-core

HarmonyOS（OHOS aarch64）的 Homebrew tap：收录尚未回流官方 [Harmonybrew/homebrew-core](https://atomgit.com/Harmonybrew/homebrew-core) 的 formula（Bun 自举链、AI CLI 等），稳定后合入上游。

> ⚠️ **早期阶段** — 仅在开发机做过构建 / 安装 / smoke 验证，未覆盖多机型多系统版本，不保证生产可用。

## 安装

```bash
brew tap social4hyq/core https://atomgit.com/social4hyq/homebrew-core.git
brew trust social4hyq/core         # Homebrew 6.0+ 必须显式信任第三方 tap

# 只装 bun：
brew install bun

# 装 ohos-opencode（上游源码构建的单体二进制，推荐）：
brew install ohos-opencode

# 或装预编译二进制路线的 opencode：
brew install opencode

# 只装 claude-code / grok-build / cc-switch（均从官方渠道拉取二进制 + 自签，依赖均已有 bottle）：
brew install claude-code
brew install grok-build
brew install cc-switch
```

装完跑一次 smoke：

```bash
bun --version && bun -e 'console.log(2**32, Math.PI)'
ohos-opencode --version
opencode --version
claude --version
grok --version
cc-switch --version
```

zsh 补全（`ohos-opencode` / `grok` / `cc-switch`）随 bottle 装入 `share/zsh/site-functions/`，brew 的 zsh 环境开箱即用。

## Formulae

| Formula | 版本 | 定位 |
|---|---|---|
| `ohos-opencode` | 1.18.4 | OpenCode AI 编码代理 CLI，**上游源码构建**（`bun build --compile` 单体二进制，compile target `bun-linux-arm64-ohos`）；原生依赖走 `@ohos-ports/*` npm 包。命令名 `ohos-opencode`，与官方 `opencode-ai` npm 包区分 |
| `opencode` | 1.18.4 | 同一 CLI 的**预编译 musl 二进制**路线（从 npmmirror 拉取 `opencode-linux-arm64-musl`）；注入 RUNPATH 补 Alpine libstdc++/libgcc，wrapper LD_PRELOAD `ohos-compat-shim` + `dlopen-sign-shim` |
| `claude-code` | 2.1.218 | Anthropic Claude Code CLI；**runtime-fetch stub**（Anthropic License 不允许重分发官方二进制），首次运行拉取 + 校验 sha256 + 自签 + 缓存 |
| `grok-build` | 0.2.111 | xAI Grok Build CLI；完全静态 ELF，仅 `ohos-bst-light` self-sign，无需 shim/RUNPATH；bash/zsh/fish 补全 |
| `cc-switch` | 5.9.2, revision 1 | AI coding CLI 供应商切换器 + 本地代理（预编译静态 ELF，仅 `ohos-bst-light` self-sign）；主要用于给 codex 桥接 Chat-Completions-only provider（Kimi/DeepSeek 等） |
| `bun` | 1.4.0, revision 34 | Bun JavaScript runtime（`social4hyq/ohos-bun` 的 `ohos-aarch64` 分支）；`ohos-compat-shim` 已**静态内嵌**进可执行文件（覆盖 bun 及所有 `bun build --compile` 产物），无 LD_PRELOAD wrapper |
| `bun-bootstrap` | 1.4.0-5467a689 | 预编译 bun，用来启动 `bun bd` 自举本机 bun；已预签，无需 ohos-sdk（`keg_only`） |
| `bun-webkit` | `4895f45dfb` | JavaScriptCore / WTF / bmalloc 静态库，bun 专用 WebKit fork（`keg_only`） |
| `llvm@21` | 21.1.8, revision 2 | OHOS 补丁版 clang + lld + multiarch runtime libs；链接期 LLD `--code-sign` 签名（裁剪版，`keg_only`） |
| `icu4c@78` | 78.3, revision 1 | Unicode 库，用本仓库 llvm@21 重编以对齐 libc++ ABI（`keg_only`） |
| `ohos-bst-light` | 1.0.0 | 轻量二进制自签工具，保留 ELF 结构不被破坏；预编译二进制 formula 的 self-sign 都靠它 |
| `ohos-compat-shim` | 0.2.0 | LD_PRELOAD 兼容垫片：拦截鸿蒙缺失/异常的 syscall（`close_range`/`fchmodat2`/`getpwuid_r`/`tmpfile`/`getcwd`/`linkat`/`symlinkat` 等）；`opencode`/`claude-code` 共用 |
| `dlopen-sign-shim` | 0.1.0 | LD_PRELOAD 垫片：`dlopen`/`dlmopen` 前自动 self-sign 未签名 ELF，兜底运行时才解包落盘的原生模块 |

> 已下线：`close-range-shim`（2026-07-15，并入 `ohos-compat-shim`）；`bun-pty` / `lightningcss` / `tailwindcss-oxide`（2026-07-18，`ohos-opencode` 改走 `@ohos-ports/*` npm 包后 formula 失去存在意义）；`codex`（2026-07-23，harmonybrew 官方已原生支持 codex，本 tap 自建 formula 失去存在意义）。

## Bottle

所有 bottle 面向 `arm64_ohos`，托管在 atomgit releases，tag 以各 formula 的 `root_url` 为准；`bun-bootstrap` 为预编译 binary pour。

## 已知限制

### 系统调用降级

`ohos-compat-shim` 以两种形态生效：`opencode` / `claude-code` 经 wrapper LD_PRELOAD 它；bun（r31+）把它静态内嵌进可执行文件，覆盖所有 `bun build --compile` 产物（含 `ohos-opencode`）。使用者一般不用关心，极端场景下能感知到：

| 类别 | 鸿蒙缺什么 | 降级方式 | 用户能感知到的影响 |
|---|---|---|---|
| 部分 syscall | `close_range` / `openat2` / `epoll_pwait2` / `memfd` / `fchmodat2` / `pidfd` 返 `ENOSYS` | shim 拦截并退到老 syscall（`close` 循环 / `openat` + `O_PATH` / `epoll_pwait` 等） | 冷启动略慢，高并发 IO 吞吐低于 Linux 基线 |
| 文件系统 | `linkat` 跨 hmdfs 分区返 `EPERM`；`getcwd` 在 hmdfs 上偶发失败；`/tmp` 只读 | shim 提供 `linkat`/`symlinkat`/`getcwd` 兜底；临时文件走 `$TMPDIR` | 跨分区硬链接退化成复制；`$TMPDIR` 必须指向可写分区 |
| 进程模型 | `vfork` 在 OHOS 不可靠 | `vfork → fork` | spawn 比 Linux 略重，功能无差异 |
| 平台名 | npm 生态没有 OHOS 概念 | `process.platform === "openharmony"`，`bun install --os=openharmony` 可用 | 三方包若 hard-code `linux` 需手动映射 |

### 其他

- **签名按产物来源分四条路径**：bun 内置 `ohos_sign` crate（in-process，零 fork）；`llvm@21` 的 cc/c++ shim（LLD `--code-sign`，链接期）；预编译二进制（claude-code/grok-build/opencode/cc-switch）用 `ohos-bst-light` self-sign；运行时才解包的原生模块由 `dlopen-sign-shim` 兜底。
- `claude-code` 遵循 Anthropic License，不在 bottle 里重分发官方二进制：安装的是 runtime-fetch 包装脚本，首次运行下载、校验 sha256、自签并缓存。
- `opencode`（prebuilt）动态链接的 GCC 运行时（`libstdc++.so.6`/`libgcc_s.so.1`）OHOS 不自带，靠 Alpine musl 静态资源 + 就地 RUNPATH 注入解决。
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

适配的长期目标是推回上游，消除 formula 层 workaround。当前 open：[lightningcss#1264](https://github.com/parcel-bundler/lightningcss/pull/1264)、[@tailwindcss/oxide#20276](https://github.com/tailwindlabs/tailwindcss/pull/20276)。合并并发布后，对应 `@ohos-ports/*` 包会 `npm deprecate`，`ohos-opencode` 的依赖 override 切回官方包。

## 反馈

遇到功能差异或崩溃，请附：HarmonyOS 版本、`bun --version`、复现命令、是否触及上面降级表里的类别。Bun / Rust 一旦发布官方 OHOS aarch64 版本，本仓库会优先切到上游产物，过渡 formula 简化或下线。
