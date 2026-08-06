# social4hyq/homebrew-core

HarmonyOS（OHOS aarch64）的 Homebrew tap：为鸿蒙 PC 移植主流开发工具链，收录尚未回流官方 [Harmonybrew/homebrew-core](https://atomgit.com/Harmonybrew/homebrew-core) 的 formula，稳定后合入上游。现役 20 个 formula，覆盖 **AI coding CLI**（`opencode`/`opencode@2`/`claude-code`/`grok-build`/`reasonix`/`cc-switch`）、**Bun 自举链**（`bun`/`bun-bootstrap`/`bun-webkit`/`llvm@21`/`icu4c@78`）、**签名与兼容垫片**（`ohos-bst-light`/`ohos-compat-shim`/`inject-runpath`/`dlopen-sign-shim`）、**终端与工具**（`qemu-aarch64`/`sshport`/`starship`/`zellij`/`hishell-font`）。

> ⚠️ **平台现实**（详见下文「已知限制」）：鸿蒙 PC 上 ELF 必须两层签名（LLD `--code-sign` + `binary-sign-tool`/`ohos-bst-light`）方可执行；`close_range`/`fchmodat2`/`getpwuid_r`/`tmpfile`/`linkat` 等缺失或返错（含 `SIGSYS`），依赖 `ohos-compat-shim` 降级；`openat2`/`memfd` 等需源码级移植；ptrace / 内核日志对用户态不可用，调试靠 `qemu-aarch64 -strace` 等替代；`/tmp` 只读。验证状态：`opencode` 与 `bun` 已在本机真机跑过官方用例完整测试（通过率 99% 以上），其余 formula 均经真机构建 / 安装 / smoke 验证；尚未覆盖多机型、多系统版本。

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
# 只装 claude-code / grok-build / cc-switch（claude-code 首次运行拉取官方二进制 + 自签；grok-build / cc-switch 为预编译 bottle，均已自签）：
brew install claude-code
brew install grok-build
brew install cc-switch

# 装 qemu-aarch64（用户态 QEMU，strace 替代品 —— 鸿蒙 6.1 自签二进制无 ptrace 权限）：
brew install qemu-aarch64

# 装 reasonix（DeepSeek 原生终端 AI coding agent，Go 源码构建静态 ELF）：
brew install reasonix
```

装完跑一次 smoke：

```bash
bun --version && bun -e 'console.log(2**32, Math.PI)'
opencode --version
opencode2 --version
claude --version
grok --version
cc-switch --version
qemu-aarch64 --version && qemu-aarch64 -strace /bin/true
reasonix --version
```

shell 补全随 bottle 装入，开箱即用。以生成式为主（`generate_completions_from_executable`，跟随二进制不漂移）：`opencode2` / `grok` / `cc-switch` 三 shell（bash/zsh/fish）齐全；`bun` 装源码树自带的静态三 shell 补全（同官方 formula）；`opencode` 的上游生成器（yargs）只产 bash 脚本，故 bash 用生成的、zsh 另有手写补全、fish 无。

## Formulae
| `opencode` | 1.18.14 | OpenCode AI 编码代理 CLI；上游源码构建（`bun build --compile` 单体二进制，原生依赖走 `@ohos-ports/*` npm 包） |
| `opencode@2` | 2.0.0-beta, revision 9 | opencode v2 预览路线；源码构建（`bun build --compile` 单体二进制，原生依赖 `@ohos-ports/opentui-core` + `@ohos-ports/bun-pty`），命令名 `opencode2` |
| ~~`opencode-shim`~~ | —（已下线 2026-08-02） | 预编译 musl 二进制路线已被源码构建路线（`opencode`）取代，formula 随之下线 |
| ~~`opencode-shim@2`~~ | —（已下线 2026-08-02） | v2 预编译二进制路线已被源码构建路线（`opencode@2`）取代，formula 随之下线 |
| `claude-code` | 2.1.223 | Anthropic Claude Code CLI；runtime-fetch stub（License 禁重分发），首次运行拉取 + 校验 sha256 + 自签 |
| `grok-build` | 0.2.118, revision 1 | xAI Grok Build CLI；预编译静态 musl ELF，仅 `ohos-bst-light` self-sign |
| `reasonix` | 1.20.0 | DeepSeek 原生终端 AI coding agent；Go 源码构建（`CGO_ENABLED=0` 静态 ELF），签名同 grok-build，`inreplace` 修 `/tmp` 锁目录 |
| `cc-switch` | 5.9.2, revision 2 | AI coding CLI 供应商切换器 + 本地代理；预编译静态 ELF（`ohos-bst-light` self-sign），给 codex 桥接 Chat-Completions-only provider |
| ~~`codex`~~ | —（已下线 2026-07-23） | OpenAI Codex CLI。**已由 Harmonybrew 官方上游原生提供**，请直接 `brew install codex`（官方 core），本 tap 的自建 formula 已随之下线 |
| `bun` | 1.4.0, revision 51 | Bun JavaScript runtime；**自举源码构建**（`bun bd`），`ohos-compat-shim` 静态内嵌进可执行文件 |
| `bun-bootstrap` | 1.4.0-5467a689, revision 1 | 预编译 bun，用于 `bun bd` 自举本机 bun；已预签（`keg_only`） |
| `bun-webkit` | `34c01d1339` | bun 专用 WebKit fork 静态库（JSCore/WTF/bmalloc）；CMake 源码构建（`--target=aarch64-linux-ohos`，`keg_only`） |
| `llvm@21` | 21.1.8, revision 4 | OHOS 补丁版 clang + lld + multiarch runtime libs；链接期 LLD `--code-sign` 签名（`keg_only`） |
| `icu4c@78` | 78.3, revision 2 | Unicode 库；用本仓库 `llvm@21` 重编对齐 libc++ ABI（`keg_only`） |
| `ohos-bst-light` | 1.0.0, revision 1 | 轻量二进制自签工具（保留 ELF 结构）；预编译二进制 formula 的 self-sign 都靠它 |
| `ohos-compat-shim` | 0.2.8 | LD_PRELOAD 兼容垫片：拦截鸿蒙缺失/异常 syscall（`close_range`/`fchmodat2`/`getpwuid_r` 等）；C 源码直编；`claude-code` 共用 |
| `inject-runpath` | 0.2.0, revision 1 | 就地注入 DT_RUNPATH 到 ELF（零偏移移动，不破坏 bun 产物模块图；`keg_only`） |
| `dlopen-sign-shim` | 0.1.0, revision 1 | LD_PRELOAD 垫片：`dlopen`/`dlmopen` 前自动 self-sign 未签名 ELF；C 源码直编，运行时调用 `ohos-bst-light` |
| `qemu-aarch64` | 11.0.1-r0 | QEMU 用户态 aarch64 模拟器；Alpine 全静态 musl 构建，`-strace` 纯用户态 syscall 跟踪（替代 ptrace） |
| `sshport` | 0.2.1 | SSH 端口转发：`sshport up <host>` 把远程端口同号映射到本机；TS 源码构建（`bun build` 单 JS 文件） |
| `starship` | 1.26.0, revision 2 | 跨 shell 提示符；Rust 源码构建 |
| `zellij` | 0.45.0-dev | 终端复用器 + WASM 插件系统（wasmi 解释执行）；Rust 源码构建，跟踪 `main` 固定 revision，wrapper 内置 `ohos-compat-shim` |
| `hishell-font` | 0.1.0 | hishell 终端 Nerd Font 安装配置；TS 源码构建（`bun build` 单 JS 文件） |
> 已下线：`close-range-shim`（2026-07-15，并入 `ohos-compat-shim`）；`bun-pty` / `lightningcss` / `tailwindcss-oxide`（2026-07-18，`ohos-opencode` 改走 `@ohos-ports/*` npm 包后 formula 失去存在意义）；`codex`（2026-07-23，改由 Harmonybrew 官方上游提供，见上表）；`opencode-shim` / `opencode-shim@2`（2026-08-02，预编译 shim 路线已由源码构建路线 `opencode` / `opencode@2` 完全取代）。
>
> 改名（2026-08-01）：`opencode` → `opencode-shim`、`opencode@2` → `opencode-shim@2`（预编译 shim 路线）；`ohos-opencode` → `opencode`、`ohos-opencode@2` → `opencode@2`（源码构建路线，命令名同步改为 `opencode` / `opencode2`）。bottle 不随改名自动迁移，已装旧名的用户请先 `brew uninstall <旧名>` 再 `brew install <新名>`。

## 命名与冲突约定

新增 formula 前，以及给某个 formula 写任何面向用户的引用（`depends_on`、`Formula[...]`、README/CLAUDE.md 里的 `brew install` 命令）时，遵守三条规则：

1. **先探测是否与 harmonybrew/core 同名**：`brew info homebrew/core/<name>` 能解析出 stable 版本即为冲突（容器内跑要注意 `HOMEBREW_NO_INSTALL_FROM_API=1` 是常驻环境变量，会让这条探测静默失效，需要 `env -u HOMEBREW_NO_INSTALL_FROM_API` 先去掉它；`.github/scripts/light-check.sh` 会在 PR 里自动跑这条探测并给 warning，不 block）。
2. **同名则该 formula 的所有引用必须写 tap 全限定名** `social4hyq/core/<name>`，不能裸名。原因：Homebrew 的 `Formulary` 解析裸名优先走官方 API（`FromAPILoader` 先于 `FromTapLoader`/`FromNameLoader`），官方有同名 formula 就静默拿官方版，不报歧义、不报错——`brew install`（未装过）会中招，`brew upgrade`/`brew reinstall`（已装过，走 keg 自身 receipt）不受影响。当前冲突集合两个：`icu4c@78`、`zsh`（两者版本号都恰好和官方一致，尤其容易被当成同一个东西）。
3. **两个 formula 装出同名 bin 时**，优先级 `keg_only` > 改名（如 `opencode@2` 的 `opencode2`）> `conflicts_with`。前两者已覆盖本 tap 当前全部重叠场景（`llvm@21`/`bun-webkit`/`bun-bootstrap` 均 `keg_only`；`opencode@2` 改名避让 `opencode`），`conflicts_with` 留作两个都必须 link 且无法改名时的最后手段。


## Bottle

所有 bottle 面向 `arm64_ohos`，托管在 atomgit releases，tag 以各 formula 的 `root_url` 为准；`bun-bootstrap` 为预编译 binary pour。

## 已知限制

### 系统调用降级

`ohos-compat-shim` 以两种形态生效：`claude-code` 经 wrapper LD_PRELOAD 它；bun（r31+）把它静态内嵌进可执行文件，覆盖所有 `bun build --compile` 产物（含 `opencode` / `opencode2`）。使用者一般不用关心，极端场景下能感知到：

| 类别 | 鸿蒙缺什么 | 降级方式 | 用户能感知到的影响 |
|---|---|---|---|
| syscall | `close_range`（真机 `SIGSYS`）；`syscall(SYS_fchmodat2)`（真机 `SIGSYS`，OpenHarmony 容器 `ENOSYS`） | shim 拦截：`close_range` → `close` 循环；`fchmodat2` → `chmod` 等值替代 | 冷启动略慢，高并发 IO 吞吐低于 Linux 基线 |
| libc 函数 | `getpwuid_r` 返 `rc=0, *result=NULL`（Node `os.userInfo()` 抛异常）；`tmpfile` 返 `NULL/EPERM`（沙箱 `P_tmpdir` 不可写） | shim 兜底：`getpwuid_r` → `OH_OsAccount_GetName` + `$LOGNAME`/`$USER` 回落；`tmpfile` → 改走 `$TMPDIR` 下的可写目录 | `os.userInfo()` 可用；临时文件必须走 `$TMPDIR`（指向可写分区） |
| 文件系统 | `linkat`/`symlinkat` 在沙箱安装目录返 `EPERM`/`EACCES`；`getcwd` 父目录缺 `+x` 返 `EACCES`、cwd 被删后返 `ENOENT` | shim 兜底：`linkat`/`symlinkat` → 同目录隐藏临时文件 + `renameat` 原子拷贝（无 0 字节残留）；`getcwd` → `readlink("/proc/self/cwd")`（内核侧解析真实路径）+ `$HOME` 兜底 | 跨分区硬链接退化成复制；`bun run`/生命周期脚本的 `getcwd` 不再炸 |
| 管道 I/O | `splice` 两处缺陷：源端 EOF 返 `-1/EPIPE`（Linux 返 `0`）；写入管道的数据不唤醒已阻塞的 `poll`/`epoll_wait` | shim 修复 EOF 语义 + bounce buffer 唤醒路径（hook `poll`/`ppoll`/`epoll_pwait`/`epoll_ctl`） | 文件尾误报错误、轮询型管道消费端死锁均消除 |

> **LD_PRELOAD 够不着、需源码级移植的**（不做 shim）：`openat2`/`epoll_pwait2`（bun 的 rustix `linux_raw` 内联 syscall 路径，不经过 libc 符号）、`memfd`、`pidfd`、`vfork`。

### 问题定位手段

鸿蒙 PC 的安全管控使常规 UNIX-like 调试手段大部分不可用，当前可用路径：

| 手段 | 状态 | 替代/用法 |
|---|---|---|
| 进程跟踪（ptrace） | **受限**：HarmonyOS 6.1 下自签名二进制无法持有 ptrace 权限，自编译的 gdb / lldb / strace 均不可用 | strace 用本 tap 的 `qemu-aarch64 -strace` 替代（纯用户态拦截转发，非虚拟机，无需 ptrace，已实测可用） |
| 内核日志 | `dmesg` / `/dev/kmsg` 存在但不向用户开放 | `hilog -t kmsg`；用进程名或安全模块名过滤：`avc`（selinux 拦截）/ `xpm`（验签不通过）/ `hmsecpt`（seccomp 拦截） |
| proc 文件系统 | 部分开放 | `/proc/self/*` 几乎完全开放，其余路径自行尝试 |
| 内核打点（ftrace / eBPF） | 不可用 | 需内核支持，当前无替代 |

### 其他

- **签名按产物来源分四条路径**：bun 内置 `ohos_sign` crate（in-process，零 fork）；`llvm@21` 的 cc/c++ shim（LLD `--code-sign`，链接期）；预编译二进制（claude-code/grok-build/cc-switch/qemu-aarch64）用 `ohos-bst-light` self-sign；`opencode` / `opencode2` 的 `.codesign` 段由 bun compile 直接产生（bun 内置 `ohos_sign`）；运行时才解包的原生模块由 `dlopen-sign-shim` 兜底。
- WebKit Inspector 走 socket 后端而非 glib 后端（OHOS 没有 GLib）。

## 核心能力确认

以下能力已在 HarmonyOS aarch64 上验证通过（bun 1.4.0 r51 / qemu-aarch64 11.0.1）：

| 能力 | 状态 | 说明 |
|------|------|------|
| **JIT** (DFG + FTL) | JIT 三层全开 | `ENABLE_JIT=1`, `ENABLE_DFG_JIT=1`, `ENABLE_FTL_JIT=1`；`fib(25)×20` 14ms（解释器需 >800ms） |
| **Wasm JIT** (BBQ + OMG) | 已启用 | `ENABLE_WEBASSEMBLY_BBQJIT=1`, `ENABLE_WEBASSEMBLY_OMGJIT=1` |
| **NAPI** (node-gyp) | 100% 通过 | bun 自动配置 `CC=cc CXX=c++ LDFLAGS=-Wl,--code-sign`；需 `brew install llvm@21` |
| **Workspace 签名** | 已修复 | `bun install` 对 hoisted + isolated linker 的 `.node`/`.so` 均自动签名 |

## 上游

适配的长期目标是推回上游，消除 formula 层 workaround。当前仍 open（2026-08 未合并）：[lightningcss#1264](https://github.com/parcel-bundler/lightningcss/pull/1264)、[@tailwindcss/oxide#20276](https://github.com/tailwindlabs/tailwindcss/pull/20276)。合并并发布后，对应 `@ohos-ports/*` 包会 `npm deprecate`，`opencode` 的依赖 override 切回官方包。

已有回流成果：`codex` 于 2026-07-23 起由 [Harmonybrew 官方 core](https://atomgit.com/Harmonybrew/homebrew-core) 原生提供，本 tap 的自建 formula 同步下线（见 Formulae 表）。

## 反馈

遇到功能差异或崩溃，请附：HarmonyOS 版本、`bun --version`、复现命令、是否触及上面降级表里的类别。Bun / Rust 一旦发布官方 OHOS aarch64 版本，本仓库会优先切到上游产物，过渡 formula 简化或下线。
