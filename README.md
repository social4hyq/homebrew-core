# social4hyq/homebrew-core

HarmonyOS（OHOS aarch64）的 Homebrew tap：提供已在真机验证的开发工具链——AI coding CLI（`opencode` / `claude-code` / `grok-build` / `reasonix` / `cc-switch`）、Bun 运行时（`bun` / `bun-webkit` / `llvm@21` 等）、终端与调试工具（`qemu-aarch64` / `starship` / `zellij` / `sshport` 等）。所有二进制均已按 HarmonyOS 要求完成签名，安装后开箱即用。

## 安装

```bash
brew tap social4hyq/core https://atomgit.com/social4hyq/homebrew-core.git
brew trust social4hyq/core   # Homebrew 6.0+ 必须显式信任第三方 tap

# 常用工具：
brew install opencode        # AI 编码代理（v2 预览：brew install opencode@2）
brew install claude-code     # Claude Code CLI
brew install grok-build      # Grok Build CLI
brew install reasonix        # DeepSeek 终端 coding agent
brew install cc-switch       # AI CLI 供应商切换器
brew install bun             # Bun 运行时
brew install starship        # 跨 shell 提示符
brew install zellij          # 终端复用器
brew install qemu-aarch64    # 用户态 QEMU（strace 替代品）
```

## 验证安装

```bash
bun --version && bun -e 'console.log(2**32, Math.PI)'
opencode --version
opencode2 --version
claude --version
grok --version
reasonix --version
cc-switch --version
starship --version
zellij --version
qemu-aarch64 --version && qemu-aarch64 -strace /bin/true
```

shell 补全随安装自动装入（bash / zsh / fish），开箱即用。

## Formulae

| Formula | 版本 | 说明 |
|---|---|---|
| `opencode` | 1.18.14 | OpenCode AI 编码代理 CLI；上游源码构建（`bun build --compile` 单体二进制，原生依赖走 `@ohos-ports/*` npm 包） |
| `opencode@2` | 2.0.0-beta, revision 9 | opencode v2 预览路线；源码构建（`bun build --compile` 单体二进制，原生依赖 `@ohos-ports/opentui-core` + `@ohos-ports/bun-pty`），命令名 `opencode2` |
| `claude-code` | 2.1.223 | Anthropic Claude Code CLI；runtime-fetch stub（License 禁重分发），首次运行拉取 + 校验 sha256 + 自签 |
| `grok-build` | 0.2.118, revision 1 | xAI Grok Build CLI；预编译静态 musl ELF，仅 `ohos-bst-light` self-sign |
| `reasonix` | 1.20.0 | DeepSeek 原生终端 AI coding agent；Go 源码构建（`CGO_ENABLED=0` 静态 ELF），签名同 grok-build，`inreplace` 修 `/tmp` 锁目录 |
| `cc-switch` | 5.9.2, revision 2 | AI coding CLI 供应商切换器 + 本地代理；预编译静态 ELF（`ohos-bst-light` self-sign），给 codex 桥接 Chat-Completions-only provider |
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

## 已下线 / 已迁移

| Formula | 状态 | 替代方案 |
|---|---|---|
| `codex` | 2026-07-23 下线 | 已由 [Harmonybrew 官方 core](https://atomgit.com/Harmonybrew/homebrew-core) 原生提供，直接 `brew install codex` |
| `opencode-shim` / `opencode-shim@2` | 2026-08-02 下线 | 预编译 shim 路线已被源码构建路线取代，改用 `opencode` / `opencode@2` |
| `close-range-shim` | 2026-07-15 下线 | 功能并入 `ohos-compat-shim` |
| `bun-pty` / `lightningcss` / `tailwindcss-oxide` | 2026-07-18 下线 | 改走 `@ohos-ports/*` npm 包，无独立 formula 需求 |

> 改名提示（2026-08-01）：`ohos-opencode` → `opencode`、`ohos-opencode@2` → `opencode@2`（命令名同步改为 `opencode` / `opencode2`）。bottle 不随改名自动迁移，已装旧名的用户请先 `brew uninstall <旧名>` 再 `brew install <新名>`。

## 已知限制

HarmonyOS 与 Linux 存在少量系统调用差异，本 tap 通过 `ohos-compat-shim`（预加载兼容层，已内嵌进 bun 及所有 bun 编译产物）自动处理，使用者一般无需关心。极端场景下可能感知到：

- **性能**：`close_range`/`fchmodat2` 等缺失的 syscall 由 shim 替换为兼容实现，高并发 IO 吞吐略低于 Linux 基线
- **临时文件**：沙箱内 `/tmp` 只读，`tmpfile()` 类调用由 shim 改走 `$TMPDIR`——请确保 `$TMPDIR` 指向可写分区
- **用户信息**：`getpwuid_r()` 由 shim 经 HarmonyOS 账号 API 兜底，`os.userInfo()` 等调用可用
- **文件系统**：跨分区硬链接退化为原子复制（无残留）；cwd 被删除时 `getcwd()` 回退到 `/proc/self/cwd` 解析
- **管道 I/O**：`splice()` 的 EOF 语义与 poll/epoll 唤醒问题已由 shim 修复，轮询型管道消费端不会死锁

> **上游推动**：上述差异正在推动 HarmonyOS 在后续版本中解决——缺失的 syscall（如 `close_range`、`fchmodat2`）争取随系统版本放行；沙箱受限项（可写临时目录、`linkat`/`symlinkat` 权限、用户信息解析）通过权限申请开放。平台放行后 shim 会自动切回原生实现（每次调用实时探测，无需重新安装或配置）。

## 反馈

遇到功能差异或崩溃，请在 GitHub Issues 反馈，附：HarmonyOS 版本、`bun --version`、复现命令。
