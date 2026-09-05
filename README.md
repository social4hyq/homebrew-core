# social4hyq/homebrew-core

面向鸿蒙 PC（HarmonyOS，OHOS aarch64）的 [Harmonybrew](https://harmonybrew.atomgit.com)（Homebrew 的鸿蒙移植）第三方 tap。

**这个 tap 解决什么问题**：鸿蒙 PC 的终端（HiShell）对每个可执行文件强制代码签名校验——直接下载或自行编译的 Linux 程序一律 `Permission denied`；同时不少常用开发工具尚未适配鸿蒙。本 tap 把一批常用开发工具逐一移植、签名、真机验证后打包成 bottle：`brew install` 一条命令装好即用，体验与 macOS/Linux 上的 Homebrew 一致。

**装了能做什么**：

- **让 AI 帮你写代码**：`opencode`（开源、自带 75+ 模型提供商接入）、`claude-code`（Anthropic 官方），配合 `herdr` 让 agent 会话断线不丢
- **跑现代 JavaScript/前端工具链**：`bun` 运行时、`node-ohos`、`vite-plus` 统一前端工具链
- **打造顺手的终端**：`starship` 提示符 + `hishell-font` 图标字体、`zellij` 终端工作区、`sshport` 远程端口转发
- **本地构建与排障**：`llvm@21` 编译器、`ohos-bst-light` 自签工具、`ohos-compat-shim` 兼容层、`qemu-aarch64` 用户态仿真与系统调用跟踪

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
| `opencode` | 1.18.27 | 开源的终端 AI 编程助手：在终端里用自然语言让 AI 读代码、改文件、跑命令；自带 75+ 模型提供商接入，用自己的 API key 自由选模型（v1 稳定版） |
| `opencode@2` | 0.0.0-beta-19124 | opencode 下一代 v2 的 Beta 尝鲜版（命令名 `opencode2`）：全新插件 API 与交互，与 v1 并存互不影响，版本号滚动跟进 beta 频道 |
| `claude-code` | 2.1.260 | Anthropic 官方 AI 编程助手 Claude Code 的终端版：读懂整个代码库、跨文件改代码跑测试、提 PR；需 Claude 订阅或 API 账号（License 禁随包分发，首次运行自动从官方拉取并校验完整性） |
| `herdr` | 0.8.2 | AI 编程 agent 的终端会话管家：agent 会话后台常驻，断网、合盖、重启都不丢，随时接管回来；同时跑多个 agent 时工作状态（工作中/卡住/空闲）一屏总览 |
| `bun` | 1.4.1 | 极速 JavaScript/TypeScript 一体化工具链：运行时、包管理、测试、打包四合一，可直接替代 Node.js；本 tap 多数工具的底座 |
| `bun-bootstrap` | 1.4.0-5467a689 | bun 自举构建用的预编译引导版（普通用户无需安装） |
| `bun-webkit` | `6119947592` | bun 的浏览器引擎组件（内部依赖，普通用户无需关心） |
| `node-ohos` | 26.7.0 | 用本 tap `llvm@21` 构建的 Node.js：与 bun 系原生插件 ABI 兼容，需要 node 跑原生扩展时选它（开发者向） |
| `vite-plus` | 0.2.8 | VoidZero（Vue/Vite 作者团队）的 Web 统一工具链：一个 `vp` 命令包揽创建项目、开发调试、检查、格式化、测试、构建全流程（Beta） |
| `starship` | 1.26.0 | 跨 shell 的极简高速提示符：git 状态、目录、语言版本一目了然，一套配置通吃 bash/zsh/fish；**需配合 `hishell-font`**（图标字体），否则图标显示为方框 |
| `hishell-font` | 0.1.0 | 鸿蒙 PC 自带终端（HiShell）的 Nerd Font 图标字体：`starship` 等现代终端工具的图标前置——先装它，提示符里的图标才不变方框 |
| `zellij` | 0.45.1 | 开箱即用的终端工作区（类似 tmux）：多窗格/标签页、会话断开重连不丢，键位提示直接显示在界面上不用背，支持布局与插件 |
| `sshport` | 0.2.1 | SSH 端口转发小工具：一条命令把远程开发机的服务端口映射到本机同名端口，直接访问 |
| `llvm@21` | 21.1.8 | Clang/LLD 编译器工具链：在鸿蒙 PC 上源码构建 C/C++ 的基石，构建产物自动完成代码签名（普通用户无需直接安装） |
| `ohos-bst-light` | 1.0.0 | 零依赖的鸿蒙二进制自签名工具（开发向）：鸿蒙 PC 强制验签，自己编译的程序没签名跑不起来，`self-sign <文件>` 原地签好即可执行 |
| `ohos-compat-shim` | 0.5.0 | 系统兼容层：自动兜底鸿蒙与标准 Linux 的底层行为差异，让 Linux 生态软件开箱即用（已内嵌进本 tap 产物，无需单独配置） |
| `qemu-aarch64` | 11.0.1-r0 | 用户态 QEMU：直接运行/调试 Linux aarch64 程序，自带系统调用跟踪（`-strace`），是鸿蒙无 root strace 环境下的排障替代品 |
| `libsecret` | 0.21.7 | 系统密码保险柜的标准接口库（freedesktop Secret Service 规范），附 `secret-tool` 命令：脚本可用它把 API token 等机密存进密钥环，而不是明文写进配置文件 |

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
| `nvm` | 2026-08-24 下线 | 已由 [Harmonybrew 官方 core](https://atomgit.com/Harmonybrew/homebrew-core) 原生提供（0.40.7，OHOS 平台补丁 + ohos-node.com 发行源），直接 `brew install nvm`；已装本 tap 旧版的用户请先 `brew uninstall nvm` 再装上游版 |
| `nvm-ohos` | 2026-08-15 下线 | 旧实现存档：`NVM_INSTALL_THIRD_PARTY_HOOK` 重定向 `nvm install` 到 brew node keg；其继任者本 tap `nvm` 也已于 2026-08-24 下线，统一改用官方 core 的 `nvm`；可从 tap git 历史恢复 |
| `warp-tui` | 2026-08-12 下线 | 已停止维护（使用率低）；可从 tap git 历史恢复 formula |
| `inject-runpath` / `dlopen-sign-shim` | 2026-08-12 下线 | 已无 formula 依赖（原用途已被预签名 npm `.so` + bun r31 起静态内嵌的 `ohos-compat-shim` 取代）；可从 tap git 历史恢复 formula |
| `zig@0.15` | 2026-09-04 下线 | 唯一消费者 herdr 已改为 install() 内联官方预编译 zig（resource 下载 + binary-sign-tool 签名），独立 keg 无保留必要；可从 tap git 历史恢复 formula |

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
