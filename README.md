# social4hyq/homebrew-core

HarmonyOS (OHOS aarch64) 的 Homebrew tap：收录尚未回流官方 [Harmonybrew/homebrew-core](https://atomgit.com/Harmonybrew/homebrew-core) 的 formula（Bun 自举链、AI CLI 等），稳定后合入上游。

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

# 只装 claude-code / codex / grok-build（均从官方渠道拉取二进制 + 自签，依赖均已有 bottle）：
brew install claude-code
brew install codex
brew install grok-build
```

装完跑一次 smoke：

```bash
bun --version && bun -e 'console.log(2**32, Math.PI)'
ohos-opencode --version
claude --version
codex --version
grok --version
```

zsh 补全（`ohos-opencode` / `codex` / `grok`）随 bottle 装入 `share/zsh/site-functions/`，brew 的 zsh 环境开箱即用。

## Formulae

| Formula | 版本 | 定位 |
|---|---|---|
| `ohos-opencode` | 1.18.3 | OpenCode AI 编码代理 CLI，**上游源码构建**（`bun build --compile` 单体二进制，compile target `bun-linux-arm64-ohos`）；原生依赖走 `@ohos-ports/*` npm 包（opentui-core/bun-pty/lightningcss/tailwindcss-oxide）；shim 随编译产物静态内嵌，无 LD_PRELOAD、零运行时依赖；附 zsh 补全。命令名 `ohos-opencode`，与官方 `opencode-ai` npm 包区分 |
| `opencode` | 1.18.3 | 同一 CLI 的**预编译 musl 二进制**路线（从 npmmirror 拉取 `opencode-linux-arm64-musl`）；注入 RUNPATH 补 Alpine libstdc++/libgcc，wrapper LD_PRELOAD `ohos-compat-shim` + `dlopen-sign-shim` |
| `codex` | 0.144.5 | OpenAI Codex CLI；从 npmmirror 拉取 `linux-arm64` musl 静态二进制 + `ohos-bst-light` 自签；内置 ripgrep 替换为本 tap 的 musl 版；bash/zsh/fish 补全 |
| `claude-code` | 2.1.212 | Anthropic Claude Code CLI；**runtime-fetch stub**（Anthropic License 不允许重分发官方二进制），首次运行拉取 + 校验 sha256 + 自签 + 缓存 |
| `grok-build` | 0.2.102 | xAI Grok Build CLI；完全静态 ELF，仅 `ohos-bst-light` self-sign，无需 shim/RUNPATH；bash/zsh/fish 补全 |
| `bun` | 1.4.0 r33 | Bun JavaScript runtime（`social4hyq/ohos-bun` 的 `ohos-aarch64` 分支）；运行时签名由内置 `ohos_sign` crate 承担；`ohos-compat-shim` 已**静态内嵌**进可执行文件（覆盖 bun 及所有 `bun build --compile` 产物），`bin/bun` 为相对 symlink，无 LD_PRELOAD wrapper |
| `bun-bootstrap` | 1.4.0-5467a689 | 预编译 bun，用来启动 `bun bd` 自举本机 bun；已预签，无需 ohos-sdk（`keg_only`） |
| `bun-webkit` | `4895f45dfb` | JavaScriptCore / WTF / bmalloc 静态库，bun 专用 WebKit fork（`keg_only`） |
| `llvm@21` | 21.1.8, revision 2 | OHOS 补丁版 clang + lld + multiarch runtime libs；链接期 LLD `--code-sign` 签名（**裁剪版**，`keg_only`） |
| `icu4c@78` | 78.3, revision 1 | Unicode 库，用本仓库 llvm@21 重编以对齐 libc++ ABI（`keg_only`） |
| `ohos-bst-light` | 1.0.0 | 轻量二进制自签工具，保留 ELF 结构不被破坏；`codex`/`claude-code`/`grok-build`/`opencode` 等的 self-sign 都靠它 |
| `ohos-compat-shim` | 0.2.0 | LD_PRELOAD 兼容垫片：拦截 `close_range`/`fchmodat2`/`getpwuid_r`/`tmpfile`/`getcwd`/`linkat`/`symlinkat` 等（linkat/symlinkat 默认开启）；`opencode`/`codex`/`claude-code` 共用（bun 及 `bun build --compile` 产物静态内嵌副本，不是本包用户） |
| `dlopen-sign-shim` | 0.1.0 | LD_PRELOAD 垫片：`dlopen`/`dlmopen` 前调用 `ohos-bst-light` 自动 self-sign 未签名 ELF，兜底运行时才解包落盘的原生模块 |

> 已下线：`close-range-shim`（2026-07-15，并入 `ohos-compat-shim`）；`bun-pty` / `lightningcss` / `tailwindcss-oxide`（2026-07-18，原 `keg_only` 原生库 keg——`ohos-opencode` 已改走 `@ohos-ports/*` npm 包，formula 失去存在意义）。

### 双轨 opencode 的退役判据

`ohos-opencode`（源码轨，推荐）与 `opencode`（预编译轨）当前并行维护，每个上游版本双倍成本。退役条件：**源码轨自 1.19.x 起连续 2 个上游版本在真机零回归后，预编译轨标记 `deprecate! because: :superseded`**；在此之前预编译轨保留，作为源码轨回归时的对照与 bisect 参照。上游 PR（lightningcss #1264、oxide #20276）合并与否只影响 `@ohos-ports/*` 依赖来源，不改变本判据。

## Bottle

- 所有 bottle 均面向 `arm64_ohos`，托管在 atomgit releases，tag 以各 formula 的 `root_url` 为准。
- **tag 的 `-rN` 序号与 formula 的 `revision` 无对应关系**：bottle 内容（sha256）每变一次就新建一个 tag、rN 递增，而 `revision` 只在需要驱动已装用户升级时才 bump（例：ohos-opencode `revision 2` 对应 tag `-r3`）。读 formula 时不要拿两者互相推断。
- `bun-bootstrap` 为预编译 binary pour。

## Formula 引用约定

- `depends_on` / `Formula[]` 里，**与官方 harmonybrew/core 同名的 formula 必须写 tap 全限定名**，否则裸名会解析到官方版本。当前冲突集合只有 `icu4c@78`（官方 core 也有 78.3，但那是系统 clang 构建，ABI 与本 tap 的 bun/webkit 不兼容）→ 必须写 `social4hyq/core/icu4c@78`，并忽略 `brew style` 的短名建议。
- 其余名字（llvm@21、bun、bun-webkit 等官方 core 不存在的）一律用裸名，毕业迁移到官方 core 时零改动。
- 新增 formula/依赖时先探测冲突：`brew info homebrew/core/<name>` 能解析出 stable 版本即为冲突。

## 共享代码

CLI formula 的 bin/ wrapper 生成（TMPDIR 默认值、LD_PRELOAD 链、opt_libexec 自引用）收敛在 `lib/ohos_formula_helpers.rb`，CELLAR-flip 与 TMPDIR 的完整 rationale 也在该文件头部注释。改 wrapper 行为改这里；改动会影响多个 formula 的 bottle 内容，重打 bottle 前先确认生成结果是否字节级等价。

## 已知限制

### 系统调用降级

`ohos-compat-shim` 以两种形态生效：`opencode` / `codex` / `claude-code` 经 wrapper LD_PRELOAD 它；bun（r31+）把它静态内嵌进可执行文件，且覆盖所有 `bun build --compile` 产物（含 `ohos-opencode`）。使用者一般不用关心，但极端场景下能感知到：

| 类别 | 鸿蒙缺什么 | 降级方式 | 用户能感知到的影响 |
|---|---|---|---|
| 部分 syscall | `close_range` / `openat2` / `epoll_pwait2` / `memfd` / `fchmodat2` / `pidfd` 返 `ENOSYS` | shim 拦截并退到老 syscall（`close` 循环 / `openat` + `O_PATH` / `epoll_pwait` 等） | 冷启动略慢，高并发 IO 吞吐低于 Linux 基线 |
| 文件系统 | `linkat` 跨 hmdfs 分区返 `EPERM`；`getcwd` 在 hmdfs 上偶发失败；`/tmp` 只读 | shim 提供 `linkat`/`symlinkat`/`getcwd` 兜底；临时文件走 `$TMPDIR` | 跨分区硬链接退化成复制；`$TMPDIR` 必须指向可写分区 |
| 进程模型 | `vfork` 在 OHOS 不可靠 | `vfork → fork` | spawn 比 Linux 略重，功能无差异 |
| 平台名 | npm 生态没有 OHOS 概念 | `process.platform === "openharmony"`，`bun install --os=openharmony` 可用 | 三方包若 hard-code `linux` 需手动映射 |

### 其他限制

- **签名有四套并行路径，按产物来源区分**：
  - `bun` 内置 `ohos_sign` Rust crate（in-process，零 fork）—— `bun install` 装的 `.node`/`.so`、`bun build --compile` 产物、dlopen 兜底
  - `llvm@21` 的 `cc`/`c++` shim（LLD `--code-sign`，链接期签名）—— cargo build-script 产物、`icu4c@78`/`bun-webkit` 等 source-build formula 的最终产物
  - `ohos-bst-light` 的 `self-sign`（保留 ELF section 布局，不像 `binary-sign-tool` 那样可能破坏结构）—— `codex`/`claude-code`/`grok-build`/`opencode`（prebuilt）这类从 npm/官方渠道直接 fetch 的二进制，以及 vendor 的 musl 运行时库（libstdc++/libgcc）
  - `dlopen-sign-shim`（LD_PRELOAD 拦截 `dlopen`/`dlmopen`）—— 运行时才解包落盘、无法在构建期预签的原生模块（`opencode` 的 `@opentui/core` 等）
- `claude-code` 遵循 Anthropic License，不在 bottle 里重新分发官方二进制：安装的是 runtime-fetch 包装脚本，首次运行时从 npmmirror（或 registry.npmjs.org 兜底）下载、校验 sha256、用 `ohos-bst-light` 自签并缓存
- `codex` / `opencode`（prebuilt）动态链接的 GCC 运行时（`libstdc++.so.6`/`libgcc_s.so.1`）OHOS 不自带，靠 Alpine musl 静态资源 + 就地 RUNPATH 注入解决（不能用 `patchelf`，会破坏 Bun 编译产物的 module graph）
- `grok-build` 是完全静态 ELF（无 INTERP/DYNAMIC segment），不需要 `ohos-compat-shim`/RUNPATH，只做一次 self-sign
- WebKit Inspector 走 socket 后端而非 glib 后端（OHOS 没有 GLib），远程调试连接方式和上游略有差异
- `icu4c@78` 用本仓库的 `llvm@21` 重编，让 ICU 的 libc++ 符号和 `bun` / `bun-webkit` 用同一个 mangling（`__h` namespace），避免链接器找不到符号
- 自签算法参考 [hqzing/ohos-bst-light](https://github.com/hqzing/ohos-bst-light)（fs-verity descriptor + SHA-256 merkle tree + `.codesign` ELF64 section 注入）
- bottle 只覆盖 `arm64_ohos`，不提供 macOS / x86_64 等其他平台产物
- **`bun-webkit` 源码经 gh-proxy.com 第三方代理拉取**（GitHub 在 OHOS 网络环境不可靠/被断流）：完整性由 40 位 commit pin 保证（git 校验 revision，代理无法篡改而不被发现），但可用性依赖该代理存续 —— 代理失效时改回直连 github.com 或换镜像即可，formula 只需改 url 前缀

## 核心能力确认

以下能力已在 HarmonyOS aarch64 上验证通过（bun 1.4.0）：

| 能力 | 状态 | 说明 |
|------|------|------|
| **JIT** (DFG + FTL) | JIT 三层全开 | `ENABLE_JIT=1`, `ENABLE_DFG_JIT=1`, `ENABLE_FTL_JIT=1`；`fib(25)×20` 14ms（解释器需 >800ms） |
| **Wasm JIT** (BBQ + OMG) | 已启用 | `ENABLE_WEBASSEMBLY_BBQJIT=1`, `ENABLE_WEBASSEMBLY_OMGJIT=1` |
| **NAPI** (node-gyp) | 100% 通过 | bun 自动配置 `CC=cc CXX=c++ LDFLAGS=-Wl,--code-sign`；需 `brew install llvm@21` 提供签名工具链 |
| **Workspace 签名** | 已修复 | `bun install` 对 hoisted + isolated linker 的 `.node`/`.so` 均自动签名 |

> JIT 验证命令：`bun -e "function fib(n){return n<=1?n:fib(n-1)+fib(n-2)};for(let i=0;i<5;i++)fib(25);const s=Date.now();for(let i=0;i<20;i++)fib(25);console.log(Date.now()-s+'ms',Date.now()-s<800?'JIT✓':'interpreter')"`

## 依赖关系

**构建链**（自底向上，重编下游前须先更新上游）：

```
llvm@21 → icu4c@78 → bun-webkit → bun → ohos-opencode
                ↘ bun-bootstrap（预编译，自举 bun bd 用）
```

- `ohos-opencode` 的原生依赖（opentui-core/bun-pty/lightningcss/tailwindcss-oxide）来自 `@ohos-ports/*` npm 包，不是本 tap 的 formula。
- **支撑层**：`ohos-sdk` 为构建期依赖（签名工具）；`ohos-bst-light` / `ohos-compat-shim` / `dlopen-sign-shim` 三个工具 formula 也依赖它。
- **运行时 shim**：`opencode` / `codex` / `claude-code` 的 wrapper LD_PRELOAD `ohos-compat-shim`；`opencode` 另 LD_PRELOAD `dlopen-sign-shim`（后者运行时调用 `ohos-bst-light`）；`bun` 及 `bun build --compile` 产物（含 `ohos-opencode`）自 r31 起静态内嵌 shim，无运行时 shim 依赖。

## 上游 PR 进展

本仓库的长期目标是把适配推回上游，消除 formula 层 workaround。

| 包 | PR | 状态 |
|---|---|---|
| `lightningcss` | [parcel-bundler/lightningcss#1264](https://github.com/parcel-bundler/lightningcss/pull/1264) | 已提交，待合并 |
| `@tailwindcss/oxide` | [tailwindlabs/tailwindcss#20276](https://github.com/tailwindlabs/tailwindcss/pull/20276) | 已提交，评审意见已处理，待合并 |

PR 合并并发布后，对应 `@ohos-ports/*` 包会 `npm deprecate`，`ohos-opencode` 的依赖 override 切回官方包；预编译二进制路线的 `opencode` 不受影响 —— 它本来就是纯 vendor 二进制，不做本地构建。

## 变更历史

变更历史见 git log（`git log --oneline`），不再在 README 中逐条维护。

## 反馈与贡献

- 遇到功能差异或崩溃，请附：HarmonyOS 版本、`bun --version`、复现命令、是否触及上面表格里的降级类别
- Bun / Rust 一旦发布官方 OHOS aarch64 版本，本仓库会优先切到上游产物，过渡 formula 简化或下线
