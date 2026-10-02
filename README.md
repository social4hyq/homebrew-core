# Harmonybrew 第三方 tap · 鸿蒙 PC 工具链

致力于补齐鸿蒙 PC 工具链：**Agent 工具**（opencode、Claude Code 等）、**前端构建**（vite-plus 等）和**效率工具**（终端字体、端口转发等）。formula 经移植、签名、真机验证后打包成 bottle，`brew install` 一条命令装好即用。[Harmonybrew](https://harmonybrew.atomgit.com) 是 Homebrew 的鸿蒙移植。

> 已向 [Harmonybrew 官方 core](https://atomgit.com/Harmonybrew/homebrew-core) 贡献并合入 **14 个 formula（18 个 PR）**，见下方「[贡献](#贡献)」。
>
> npm 包的鸿蒙适配在社区仓 [ohos-npm-ports/ohos-npm-ports](https://github.com/ohos-npm-ports/ohos-npm-ports) 持续进行，项目里的 npm 包装不上或跑不起来时，先到那里找适配包。

## 快速开始

```bash
brew tap social4hyq/core https://atomgit.com/social4hyq/homebrew-core.git
brew trust social4hyq/core   # Homebrew 6.0+ 必须显式信任第三方 tap

brew install social4hyq/core/opencode   # 本 tap：AI 编码代理（v1：brew install opencode-v1）
brew install claude-code                # 本 tap：Claude Code CLI
brew install vite-plus                  # 本 tap：前端工具链（`vp` 命令）
brew install hishell-font               # 本 tap：终端图标字体
brew install qemu-aarch64               # 本 tap：用户态 QEMU（含 `-strace`）
brew install bun starship               # 官方 core：Bun 运行时、终端提示符（配合 hishell-font）
```

装完用 `opencode --version`、`claude --version`、`vp --version` 验证即可。shell 补全（bash / zsh / fish）随安装自动装入。

## 本 tap 的工具

### Agent 工具

- `social4hyq/core/opencode`：终端 AI 编程助手 v2；`opencode-v1` 为 v1，两者互斥（都提供 `opencode` 命令，共享 `~/.config/opencode`）。已有用户 `brew upgrade social4hyq/core/opencode` 升到 v2，要保留 v1 则 `brew uninstall social4hyq/core/opencode && brew install opencode-v1`。因与官方 core 同名，请使用全限定名
- `claude-code` / `claude-code.latest`：Anthropic 官方 Claude Code 终端版（stable / latest 两个频道，二选一）。License 禁止再分发官方产物，安装时拉取官方 musl 二进制并自签名
- `zcode`：AI 编程工作台，终端 agent（TUI）与 Web IDE 双形态

### 前端构建

- `vite-plus`：VoidZero 的 Web 统一工具链，一个 `vp` 命令包揽创建、开发、检查、格式化、测试、构建（Beta）

### 效率工具

- `hishell-font`：鸿蒙 PC 自带终端（HiShell）的 Nerd Font 图标字体，`starship` 等的图标靠它渲染
- `sshport`：SSH 端口转发，一条命令把远程开发机的服务端口映射到本机同名端口
- `qemu-aarch64`：用户态 QEMU，可直接运行/调试 Linux aarch64 程序，自带 `-strace` 系统调用跟踪

### 基础设施

- `ohos-compat-shim`：系统兼容层，兜底鸿蒙与标准 Linux 的底层行为差异；作为依赖随 `claude-code` 自动安装，无需手动装

## 贡献

下列 formula 的鸿蒙适配由 social4hyq 提交并已合入 [Harmonybrew 官方 core](https://atomgit.com/Harmonybrew/homebrew-core)，按合入先后排列（括号内为后续修复 PR）：

| Formula | 说明 | PR |
|---|---|---|
| `lazygit` | Git 终端界面 | [!8586](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/8586) |
| `cryptography` | Python 加密库 | [!10480](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/10480) |
| `hermes-agent` | AI Agent | [!10485](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/10485) |
| `yazi` | 终端文件管理器 | [!10780](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/10780) |
| `uv` | Python 包管理器 | [!17130](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/17130) |
| `codegraph` | 代码库图谱工具 | [!17567](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/17567) |
| `zellij` | 终端复用器 | [!17569](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/17569)（[!18645](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18645)） |
| `llvm@21` | 编译器工具链 | [!18194](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18194) |
| `lld@21` | LLVM 链接器 | [!18536](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18536) |
| `libsecret` | 密钥存储库 | [!18633](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18633) |
| `herdr` | 面向 coding agent 的终端复用器 | [!18651](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18651)（[!20617](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/20617)、[!20719](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/20719)） |
| `starship` | 终端提示符 | [!18673](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18673)（[!18770](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18770)） |
| `pnpm` | Node 包管理器 | [!20806](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/20806) |
| `bun` | JavaScript 运行时与工具链 | [!21450](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/21450) |

formula 进入本 tap 的第一天起就以合入官方 core 为目标，验证成熟即推动合并、下线自有版本。

## 已迁移到官方 core

下列 formula 曾在本 tap 提供，现已由官方 core 原生提供：`codex`、`cc-switch`、`reasonix`、`deepseek-harness`、`uv`、`codegraph`、`nvm`、`llvm@21`、`lld@21`、`ohos-bst-light`、`libsecret`、`zellij`、`herdr`、`starship`、`node-ohos`、`bun`。

已装本 tap 旧版的用户请先 `brew uninstall social4hyq/core/<名>`，再 `brew install <名>`。三个特例：

- `cc-switch` 在官方 core 里叫 `cc-switch-cli`
- `node-ohos` 在官方 core 里叫 `node`
- `ohos-bst-light` 的命令名变了：本 tap 旧版装 `self-sign`，官方版装 `selfsign`（无连字符），参数不变，脚本里的调用要同步改

其余无官方替代的下线项和改名记录见 [docs/offline-history.md](docs/offline-history.md)。

## 已知限制

- **代码签名**：鸿蒙 PC 终端强制代码签名，本 tap 的产物已签名；自行编译或下载的 Linux 程序需自行签名，否则 `Permission denied`
- **系统调用差异**：缺失的 syscall、`getpwuid_r`、`splice` 唤醒等由 `ohos-compat-shim` 自动兜底，高并发 IO 吞吐略低于 Linux
- **文件系统**：沙箱内 `/tmp` 只读，临时文件走 `$TMPDIR`（请指向可写分区）；硬链接未向三方应用开放，由 shim 自动降级为复制

平台放行后 shim 会自动切回原生实现，无需重新安装。逐项说明见 [docs/known-limitations.md](docs/known-limitations.md)。

## 反馈与仓库

遇到功能差异或崩溃，请在 [GitHub Issues](https://github.com/social4hyq/homebrew-core/issues) 反馈，附：HarmonyOS 版本、`<工具> --version`、复现命令。

本仓库以 GitHub 为唯一源头（源码、Issues、PR、CI 都在这里）。[atomgit 同名仓库](https://atomgit.com/social4hyq/homebrew-core) 是单向镜像（GitHub → atomgit），只用于在国内更快地下载 bottle，请勿向其推送代码或开 PR。

## 致谢

感谢鸿蒙生态社区热心人士的分享与贡献。**hqzing** 的《鸿蒙 PC 底层开发技术详解》系列（代码签名机制、二进制自签名算法、问题定位手段等）和开源的自签工具 `ohos-bst-light` 为本 tap 的移植工作提供了重要参考，其《鸿蒙 PC 上可用的 AI Agent 工具汇总》也推荐了本 tap 的 OpenCode 移植版。相关文章（CSDN）：

- 《鸿蒙 PC 底层开发技术详解（四）：代码签名机制对我们的影响》 — https://blog.csdn.net/hqzing/article/details/160746583
- 《鸿蒙 PC 底层开发技术详解（七）：二进制自签名算法的实现》 — https://blog.csdn.net/hqzing/article/details/162642397
- 《鸿蒙 PC 底层开发技术详解（八）：鸿蒙 PC 上的问题定位手段》 — https://blog.csdn.net/hqzing/article/details/163311519
- 《在鸿蒙 PC 上使用 Claude Code（最新的 Bun 版本）》 — https://blog.csdn.net/hqzing/article/details/162758675
