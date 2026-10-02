# social4hyq/homebrew-core

[Harmonybrew](https://harmonybrew.atomgit.com)（Homebrew 的鸿蒙移植）的第三方 tap，致力于补齐鸿蒙 PC 工具链，覆盖 **Agent 工具**（opencode、Claude Code 等）、**前端构建工具**（vite-plus 等）和**效率工具**（终端字体、端口转发、系统调用跟踪等）。formula 经移植、签名、真机验证（HarmonyOS，OHOS aarch64）后打包成 bottle，`brew install` 一条命令装好即用。

**分工**：

- **本 tap**：命令行工具的 formula，验证成熟后推动合入 [Harmonybrew 官方 core](https://atomgit.com/Harmonybrew/homebrew-core)（见下方「已迁移到 Harmonybrew 官方 core」）。
- **npm 包**：前端相关工具链和大多数 npm 包的鸿蒙适配，在社区仓 [ohos-npm-ports/ohos-npm-ports](https://github.com/ohos-npm-ports/ohos-npm-ports) 持续进行。项目里的 npm 包在鸿蒙上装不上或跑不起来时，先到那里找有没有适配包。

## 安装

```bash
brew tap social4hyq/core https://atomgit.com/social4hyq/homebrew-core.git
brew trust social4hyq/core   # Homebrew 6.0+ 必须显式信任第三方 tap

# 本 tap 提供：
brew install social4hyq/core/opencode # AI 编码代理 v2（v1：brew install opencode-v1）
brew install claude-code     # Claude Code CLI
brew install vite-plus       # VoidZero 统一前端工具链（`vp` 命令）
brew install hishell-font    # 终端图标字体（提示符的图标/符号靠它渲染）
brew install qemu-aarch64    # 用户态 QEMU（`qemu-aarch64 -strace` 系统调用跟踪）

# 官方 core 提供（可选）：
brew install bun             # Bun 运行时
brew install starship        # 终端提示符美化，配合 hishell-font
```

## 验证安装

```bash
opencode --version
claude --version
vp --version
qemu-aarch64 --version && qemu-aarch64 -strace /bin/true
```

shell 补全随安装自动装入（bash / zsh / fish），开箱即用。

## Formulae

### Agent 工具

| Formula | 说明 |
|---|---|
| `opencode-v1` | 开源的终端 AI 编程助手：在终端里用自然语言让 AI 读代码、改文件、跑命令；自带 75+ 模型提供商接入，用自己的 API key 自由选模型（v1 稳定版） |
| `social4hyq/core/opencode` | opencode v2 稳定版：全新插件 API 与交互；与 `opencode-v1` 互斥，命令名同为 `opencode`，共享 `~/.config/opencode` 等目录；跟进上游 v2 发布线（升级与回退 v1 见下方说明） |
| `claude-code` | Anthropic 官方 AI 编程助手 Claude Code 的终端版：读懂整个代码库、跨文件改代码跑测试、提 PR；需 Claude 订阅或 API 账号；License 禁止再分发官方产物，故安装时拉取官方 musl 二进制，自签名后经 `ohos-compat-shim` 运行 |
| `claude-code.latest` | 同一 Claude Code 的 latest 滚动频道：安装时拉取官方 musl 二进制，自签名后经 `ohos-compat-shim` 运行；与 `claude-code` 互斥（都装 `claude` 命令，二选一） |
| `zcode` | AI 编程工作台：终端 agent（TUI）与 Web IDE 双形态；上游不发 git tag，源码取自 GitHub main、用官方 core 的 bun/pnpm 工具链在本机构建 |

> `opencode` 现为 v2，v1 为 `opencode-v1`，两者互斥（都提供 `opencode` 命令，共享 `~/.config/opencode`）。已有用户 `brew upgrade social4hyq/core/opencode` 即升到 v2；要保留 v1：`brew uninstall social4hyq/core/opencode && brew install opencode-v1`。`opencode` 与官方 core 同名，请使用全限定名。

### 前端构建

| Formula | 说明 |
|---|---|
| `vite-plus` | VoidZero（Vue/Vite 作者团队）的 Web 统一工具链：一个 `vp` 命令包揽创建项目、开发调试、检查、格式化、测试、构建全流程（Beta） |

### 效率工具

| Formula | 说明 |
|---|---|
| `hishell-font` | 鸿蒙 PC 自带终端（HiShell）的 Nerd Font 图标字体：`starship` 等现代终端工具的图标前置——先装它，提示符里的图标才不变方框 |
| `sshport` | SSH 端口转发小工具：一条命令把远程开发机的服务端口映射到本机同名端口，直接访问 |
| `qemu-aarch64` | 用户态 QEMU：直接运行/调试 Linux aarch64 程序，自带系统调用跟踪（`-strace`），是鸿蒙无 root strace 环境下的排障替代品 |

### 基础设施

| Formula | 说明 |
|---|---|
| `ohos-compat-shim` | 系统兼容层：自动兜底鸿蒙与标准 Linux 的底层行为差异，让 Linux 生态软件开箱即用；作为依赖随 `claude-code` 自动安装，无需手动装、无需配置 |

## 已迁移到 Harmonybrew 官方 core

下列 formula 曾在本 tap 提供，现已由 [Harmonybrew 官方 core](https://atomgit.com/Harmonybrew/homebrew-core) 原生提供。已装本 tap 旧版的用户请先 `brew uninstall social4hyq/core/<名>`，再 `brew install <名>`（装的是官方版）。「上游 PR」列是 social4hyq 提交到官方 core 的 PR，按合入先后排列。

| Formula | 备注 | 上游 PR |
|---|---|---|
| `codex` | — | — |
| `cc-switch` | 官方名为 `cc-switch-cli`，装 `cc-switch-cli` | — |
| `reasonix` | — | — |
| `deepseek-harness` | — | — |
| `uv` | — | [!17130](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/17130) |
| `codegraph` | — | [!17567](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/17567) |
| `nvm` | — | — |
| `llvm@21` / `lld@21` | — | [!18194](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18194) [!18536](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18536) |
| `ohos-bst-light` | **命令名变了**：本 tap 旧版装 `self-sign`，官方版装 `selfsign`（无连字符），参数不变；脚本里的调用要同步改 | — |
| `libsecret` | — | [!18633](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18633) |
| `zellij` | — | [!17569](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/17569) [!18645](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18645) |
| `herdr` | — | [!18651](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18651) [!20617](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/20617) [!20719](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/20719) |
| `starship` | 配合 `hishell-font` 用法不变 | [!18673](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18673) [!18770](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18770) |
| `node-ohos` | 官方 formula 名为 `node`，装 `node` | — |
| `bun` | 本 tap 内依赖 `bun` 的 formula 自动改用官方版 | [!21450](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/21450) |

另有未在本 tap 出现过、直接提交到官方 core 的 formula：[`lazygit`](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/8586)、[`cryptography`](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/10480)、[`hermes-agent`](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/10485)、[`yazi`](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/10780)、[`pnpm`](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/20806)。

其余已下线（无官方替代）的 formula 与改名历史见 [docs/offline-history.md](docs/offline-history.md)。

## 已知限制

HarmonyOS 与 Linux 存在少量系统调用差异，本 tap 通过 `ohos-compat-shim`（预加载兼容层，已内嵌进 bun 及所有 bun 编译产物）自动处理，使用者一般无需关心。极端场景下可能感知到：

- **代码签名**：鸿蒙 PC 终端（HiShell）强制代码签名，自行编译或直接下载的 Linux 程序会 `Permission denied`；本 tap 的产物已签名，自行构建的二进制需自行签名
- **性能**：`close_range`/`fchmodat2` 等缺失的 syscall 由 shim 替换为兼容实现，高并发 IO 吞吐略低于 Linux 基线
- **临时文件**：沙箱内 `/tmp` 只读，`tmpfile()` 类调用由 shim 改走 `$TMPDIR`——请确保 `$TMPDIR` 指向可写分区
- **用户信息**：`getpwuid_r()` 由 shim 经 HarmonyOS 账号 API 兜底，`os.userInfo()` 等调用可用
- **文件系统**：硬链接当前未向三方应用开放（`linkat` 返回 EPERM，未加载 shim 的进程直接失败）；加载 `ohos-compat-shim` 的进程由 shim 自动降级为原子复制（无残留）。cwd 被删除时 `getcwd()` 回退到 `/proc/self/cwd` 解析
- **管道 I/O**：`splice()` 的 EOF 语义与 poll/epoll 唤醒问题已由 shim 修复，轮询型管道消费端不会死锁

> **上游推动**：上述差异正在推动 HarmonyOS 在后续版本中解决——缺失的 syscall（如 `close_range`、`fchmodat2`）争取随系统版本放行；沙箱受限项（可写临时目录、`linkat`/`symlinkat` 权限、用户信息解析）通过权限申请开放。平台放行后 shim 会自动切回原生实现（每次调用实时探测，无需重新安装或配置）。

## 反馈

遇到功能差异或崩溃，请在 GitHub Issues 反馈，附：HarmonyOS 版本、`<工具> --version`、复现命令。

**仓库源头**：本仓库以 [GitHub](https://github.com/social4hyq/homebrew-core) 为唯一源头——源码托管、Issues、PR、CI 全部在 GitHub 进行。[atomgit 同名仓库](https://atomgit.com/social4hyq/homebrew-core) 是合并后自动同步的**单向镜像**（GitHub → atomgit，永不反向），存在意义是 bottle 二进制发布在 atomgit Releases 上、国内网络下载更快。反馈问题、提交贡献请认准 GitHub；请勿向 atomgit 推送代码或开 PR。

## 致谢

感谢鸿蒙生态社区热心人士的分享与贡献，为本 tap 的移植工作提供了重要参考：

- **hqzing**：《鸿蒙 PC 底层开发技术详解》系列作者（代码签名机制、二进制自签名算法、问题定位手段等），开源了二进制自签工具 `ohos-bst-light`（本 tap 早期的自签能力即来源于此，现改用 harmonybrew/core 原生提供的同名 formula），并在《鸿蒙 PC 上可用的 AI Agent 工具汇总》中推荐了本 tap 的 OpenCode 移植版。

相关文章（CSDN）：

- 《鸿蒙 PC 底层开发技术详解（四）：代码签名机制对我们的影响》 — https://blog.csdn.net/hqzing/article/details/160746583
- 《鸿蒙 PC 底层开发技术详解（七）：二进制自签名算法的实现》 — https://blog.csdn.net/hqzing/article/details/162642397
- 《鸿蒙 PC 底层开发技术详解（八）：鸿蒙 PC 上的问题定位手段》 — https://blog.csdn.net/hqzing/article/details/163311519
- 《在鸿蒙 PC 上使用 Claude Code（最新的 Bun 版本）》 — https://blog.csdn.net/hqzing/article/details/162758675
