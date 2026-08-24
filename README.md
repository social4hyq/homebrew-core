# social4hyq/homebrew-core

HarmonyOS（OHOS aarch64）的 Homebrew tap：提供已在真机验证的开发工具链——AI coding CLI（`opencode` / `claude-code`）、Bun 运行时（`bun` / `bun-webkit` / `llvm@21` 等）、Node 版本管理（`nvm`）、终端与调试工具（`qemu-aarch64` / `starship` / `zellij` / `sshport` 等）。所有二进制均已按 HarmonyOS 要求完成签名，安装后开箱即用。

## 安装

```bash
brew tap social4hyq/core https://atomgit.com/social4hyq/homebrew-core.git
brew trust social4hyq/core   # Homebrew 6.0+ 必须显式信任第三方 tap

# 常用工具：
brew install opencode        # AI 编码代理（v2 预览：brew install opencode@2）
brew install claude-code     # Claude Code CLI
brew install bun             # Bun 运行时
brew install hishell-font    # starship 图标字体（先装这个：提示符的图标/符号靠它渲染）
brew install starship        # 终端提示符美化（主题化 prompt，配合 hishell-font）
brew install zellij          # 终端复用器
brew install qemu-aarch64    # 用户态 QEMU（strace 替代品）
```

## 验证安装

```bash
bun --version && bun -e 'console.log(2**32, Math.PI)'
opencode --version
opencode2 --version
claude --version
starship --version
zellij --version
qemu-aarch64 --version && qemu-aarch64 -strace /bin/true
```

shell 补全随安装自动装入（bash / zsh / fish），开箱即用。

## Formulae

| Formula | 版本 | 说明 |
|---|---|---|
| `opencode` | 1.18.18 | 终端 AI 编码助手：在命令行里让 AI 帮你读代码、改代码、跑命令、提 PR；对话式协作 |
| `opencode@2` | 2.0.0-beta | opencode 的 v2 预览版（命令名 `opencode2`）：新架构、交互升级，仍在快速迭代 |
| `claude-code` | 2.1.235 | Anthropic 的终端 AI 编码助手（Claude Code）：对话式写代码、改代码、执行命令；首次运行自动拉取官方版本并校验完整性（License 禁随包分发） |
| `bun` | 1.4.0 | JavaScript/TypeScript 全家桶运行时：运行、打包、依赖管理一体化，启动极快 |
| `bun-bootstrap` | 1.4.0-5467a689 | bun 自举构建用的预编译引导版（普通用户无需安装） |
| `bun-webkit` | `f0f60fd232` | bun 运行时的浏览器引擎组件（内部依赖，普通用户无需关心） |
| `llvm@21` | 21.1.8 | 本 tap 的编译器基石：几乎全部本地源码构建都依赖它，并负责给最终产物签名 |
| `ohos-bst-light` | 1.0.0 | 二进制自签工具（开发向）：给本地编译的产物签名，使其能在 OHOS 上执行 |
| `ohos-compat-shim` | 0.5.0 | 系统兼容层：自动兜底 OHOS 与标准 Linux 的底层行为差异，让软件开箱即用（多数用户无感） |
| `qemu-aarch64` | 11.0.1-r0 | aarch64 程序运行/调试环境：在真机上运行 ARM Linux 程序，自带系统调用级跟踪（排查问题利器） |
| `sshport` | 0.2.1 | SSH 端口转发小工具：一条命令把远程开发机的服务端口映射到本机直接访问 |
| `starship` | 1.26.0 | 终端提示符美化/定制工具：把默认 prompt 换成主题化、信息丰富的提示符（git 状态/目录等），跨 shell 生效；**使用前先装 `hishell-font`**（图标字体），否则提示符里的图标显示为乱码 |
| `zellij` | 0.45.0-dev | 终端复用器（类似 tmux）：一个窗口多窗格/标签页，会话可脱离重连，支持插件扩展 |
| `hishell-font` | 0.1.0 | hishell 终端图标字体（Nerd Font 系）：`starship` 等带图标工具的字体前置——先装它，提示符里的图标、符号才正常显示 |
| `herdr` | 0.8.0 | AI 编码助手会话持久化：让终端里的 agent 工作上下文跨会话保留、随时续上 |
| `zig@0.15` | 0.15.2 | Zig 编程语言工具链（herdr 的构建依赖） |
| `nvm` | 0.40.6 | Node.js 多版本管理：一条命令安装/切换任意 Node 版本（OHOS 适配，下载即用） |
| `node-ohos` | 26.7.0 | 用 llvm@21 构建的 Node.js：libc++ ABI 与 bun/nan 系原生插件兼容，需要跑 node 原生扩展时用它（开发者向） |

## 已下线 / 已迁移

| Formula | 状态 | 替代方案 |
|---|---|---|
| `codex` | 2026-07-23 下线 | 已由 [Harmonybrew 官方 core](https://atomgit.com/Harmonybrew/homebrew-core) 原生提供，直接 `brew install codex` |
| `opencode-shim` / `opencode-shim@2` | 2026-08-02 下线 | 预编译 shim 路线已被源码构建路线取代，改用 `opencode` / `opencode@2` |
| `close-range-shim` | 2026-07-15 下线 | 功能并入 `ohos-compat-shim` |
| `bun-pty` / `lightningcss` / `tailwindcss-oxide` | 2026-07-18 下线 | 改走 `@ohos-ports/*` npm 包，无独立 formula 需求 |
| `icu4c@78` | 2026-08-09 下线 | libc++ ABI `__n1` 迁移（#239-#241）后本 tap fork 冗余，直接用上游 harmonybrew/core 的 `icu4c@78`（同为 `__n1`） |
| `grok-build` | 2026-08-12 下线 | 已停止维护（使用率低）；可从 tap git 历史恢复 formula |
| `cc-switch` | 2026-08-12 下线 | 已由 [Harmonybrew 官方 core](https://atomgit.com/Harmonybrew/homebrew-core) 原生提供（`cc-switch-cli`），直接 `brew install cc-switch-cli` |
| `reasonix` | 2026-08-12 下线 | 已由 [Harmonybrew 官方 core](https://atomgit.com/Harmonybrew/homebrew-core) 原生提供，直接 `brew install reasonix` |
| `deepseek-harness` | 2026-08-15 下线 | 已由 [Harmonybrew 官方 core](https://atomgit.com/Harmonybrew/homebrew-core) 原生提供（含 OHOS 补丁集：link 兜底 / 凭据模式 / ripgrep 回退 / crypto polyfill / 无沙箱放行），直接 `brew install deepseek-harness`；已装本 tap 旧版的用户请先 `brew uninstall deepseek-harness` 再装上游版 |
| `uv` | 2026-08-20 下线 | 已由 [Harmonybrew 官方 core](https://atomgit.com/Harmonybrew/homebrew-core) 原生提供（!17217，含全部三个 OHOS 补丁与 wheel 自动签名），直接 `brew install uv`；已装本 tap 旧版的用户请先 `brew uninstall uv` 再装上游版 |
| `codegraph` | 2026-08-24 下线 | 已由 [Harmonybrew 官方 core](https://atomgit.com/Harmonybrew/homebrew-core) 原生提供（!17567，无补丁单文件），直接 `brew install codegraph`；已装本 tap 旧版的用户请先 `brew uninstall codegraph` 再装上游版 |
| `nvm-ohos` | 2026-08-15 下线 | 已被本 tap 保留的 `nvm`（ohos-node.com 方案）取代；可从 tap git 历史恢复（旧实现：`NVM_INSTALL_THIRD_PARTY_HOOK` 重定向 `nvm install` 到 brew node keg） |
| `warp-tui` | 2026-08-12 下线 | 已停止维护（使用率低）；可从 tap git 历史恢复 formula |
| `inject-runpath` / `dlopen-sign-shim` | 2026-08-12 下线 | 已无 formula 依赖（原用途已被预签名 npm `.so` + bun r31 起静态内嵌的 `ohos-compat-shim` 取代）；可从 tap git 历史恢复 formula |

> 改名提示（2026-08-01）：`ohos-opencode` → `opencode`、`ohos-opencode@2` → `opencode@2`（命令名同步改为 `opencode` / `opencode2`）。bottle 不随改名自动迁移，已装旧名的用户请先 `brew uninstall <旧名>` 再 `brew install <新名>`。

## 已知限制

HarmonyOS 与 Linux 存在少量系统调用差异，本 tap 通过 `ohos-compat-shim`（预加载兼容层，已内嵌进 bun 及所有 bun 编译产物）自动处理，使用者一般无需关心。极端场景下可能感知到：

- **性能**：`close_range`/`fchmodat2` 等缺失的 syscall 由 shim 替换为兼容实现，高并发 IO 吞吐略低于 Linux 基线
- **临时文件**：沙箱内 `/tmp` 只读，`tmpfile()` 类调用由 shim 改走 `$TMPDIR`——请确保 `$TMPDIR` 指向可写分区
- **用户信息**：`getpwuid_r()` 由 shim 经 HarmonyOS 账号 API 兜底，`os.userInfo()` 等调用可用
- **文件系统**：跨分区硬链接退化为原子复制（无残留）；cwd 被删除时 `getcwd()` 回退到 `/proc/self/cwd` 解析
- **管道 I/O**：`splice()` 的 EOF 语义与 poll/epoll 唤醒问题已由 shim 修复，轮询型管道消费端不会死锁

> **上游推动**：上述差异正在推动 HarmonyOS 在后续版本中解决——缺失的 syscall（如 `close_range`、`fchmodat2`）争取随系统版本放行；沙箱受限项（可写临时目录、`linkat`/`symlinkat` 权限、用户信息解析）通过权限申请开放。平台放行后 shim 会自动切回原生实现（每次调用实时探测，无需重新安装或配置）。

## 致谢

感谢鸿蒙生态社区热心人士的分享与贡献，为本 tap 的移植工作提供了重要参考：

- **hqzing**：《鸿蒙 PC 底层开发技术详解》系列作者（代码签名机制、二进制自签名算法、问题定位手段等），开源了二进制自签工具 `ohos-bst-light`（本 tap 的自签工具即来源于此），并在《鸿蒙 PC 上可用的 AI Agent 工具汇总》中推荐了本 tap 的 OpenCode 移植版。

相关文章（CSDN）：

- 《鸿蒙 PC 底层开发技术详解（四）：代码签名机制对我们的影响》 — https://blog.csdn.net/hqzing/article/details/160746583
- 《鸿蒙 PC 底层开发技术详解（七）：二进制自签名算法的实现》 — https://blog.csdn.net/hqzing/article/details/162642397
- 《鸿蒙 PC 底层开发技术详解（八）：鸿蒙 PC 上的问题定位手段》 — https://blog.csdn.net/hqzing/article/details/163311519
- 《在鸿蒙 PC 上使用 Claude Code（最新的 Bun 版本）》 — https://blog.csdn.net/hqzing/article/details/162758675

## 反馈

遇到功能差异或崩溃，请在 GitHub Issues 反馈，附：HarmonyOS 版本、`bun --version`、复现命令。
