# Harmonybrew 第三方 tap · 鸿蒙 PC 工具链

致力于补齐鸿蒙 PC 工具链，`brew install` 即装即用。[Harmonybrew](https://harmonybrew.atomgit.com) 是 Homebrew 的鸿蒙移植。

- **Agent 工具**：`opencode`、`claude-code`、`zcode`、`hermes-agent`、`codegraph`、`herdr`
- **前端构建**：`vite-plus`、`bun`、`pnpm`
- **终端与开发效率**：`starship`、`zellij`、`lazygit`、`yazi`、`hishell-font`、`sshport`、`qemu-aarch64`（系统调用跟踪）
- **编译与语言基础**：`llvm@21`、`lld@21`、`uv`、`cryptography`、`libsecret`

> 以上除 `opencode`、`claude-code`、`zcode`、`vite-plus`、`hishell-font`、`sshport`、`qemu-aarch64` 由本 tap 提供外，其余 14 个 formula（18 个 PR）已合入 [Harmonybrew 官方 core](https://atomgit.com/Harmonybrew/homebrew-core)，见「[贡献](#贡献)」；本 tap 自维护的见「[尚未合入官方 core](#尚未合入官方-core)」。
>
> npm 包的鸿蒙适配在社区仓 [ohos-npm-ports/ohos-npm-ports](https://github.com/ohos-npm-ports/ohos-npm-ports) 持续进行，项目里的 npm 包装不上或跑不起来，先到那里找适配包。

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

装完用 `opencode --version`、`claude --version`、`vp --version` 验证。shell 补全（bash / zsh / fish）随安装自动装入。

## 本 tap 的工具

### Agent 工具

- `social4hyq/core/opencode`（v2）/ `opencode-v1`：终端 AI 编程助手，两者互斥（共用 `opencode` 命令和 `~/.config/opencode`）。升到 v2：`brew upgrade social4hyq/core/opencode`；留在 v1：`brew uninstall social4hyq/core/opencode && brew install opencode-v1`。与官方 core 同名，须用全限定名
- `claude-code` / `claude-code.latest`：Claude Code 终端版，stable / latest 两个频道，二选一。License 禁止再分发，安装时拉取官方 musl 二进制并自签名
- `zcode`：AI 编程工作台，终端 agent（TUI）与 Web IDE 双形态

### 前端构建

- `vite-plus`：VoidZero 的 Web 统一工具链，一个 `vp` 命令覆盖创建、开发、检查、格式化、测试、构建（Beta）

### 终端与开发效率

- `hishell-font`：鸿蒙 PC 终端（HiShell）的 Nerd Font 图标字体，`starship` 等的图标靠它渲染
- `sshport`：SSH 端口转发，把远程开发机的服务端口映射到本机同名端口
- `qemu-aarch64`：用户态 QEMU，直接运行/调试 Linux aarch64 程序，自带 `-strace`

### 基础设施

- `ohos-compat-shim`：系统兼容层，兜底鸿蒙与标准 Linux 的底层差异；随 `claude-code` 自动安装，无需手动装

## 贡献

social4hyq 提交并已合入官方 core 的 formula：

```mermaid
timeline
    title 合入 Harmonybrew 官方 core
    2026-05 : lazygit
    2026-06 : cryptography : hermes-agent : yazi
    2026-08 : uv : codegraph : zellij
    2026-09 : llvm@21 : lld@21 : libsecret : herdr : starship : pnpm
    2026-10 : bun
```

| Formula | 作用 | 上游 ⭐ | PR |
|---|---|---|---|
| `lazygit` | Git 终端界面，在终端里用键盘完成暂存、提交、分支、rebase 等操作 | 83k | [!8586](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/8586) |
| `cryptography` | Python 事实标准的加密库，SSH、TLS、证书、JWT 等大量 Python 库的底层依赖 | 7.8k | [!10480](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/10480) |
| `hermes-agent` | Nous Research 的自我进化 AI Agent，能从经验中沉淀出可复用的技能 | 251k | [!10485](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/10485) |
| `yazi` | Rust 编写、异步 I/O 的极速终端文件管理器，支持预览与插件 | 43k | [!10780](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/10780) |
| `uv` | Rust 编写的极速 Python 包安装器与解析器，可替代 pip、venv 等 | 90k | [!17130](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/17130) |
| `codegraph` | 面向 AI coding agent 的预索引代码知识图谱，全本地运行，让 agent 少读文件、省 token | 73k | [!17567](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/17567) |
| `zellij` | 可扩展的终端工作区，以终端复用器为基础，支持 WASM 插件 | 36k | [!17569](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/17569)（[!18645](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18645)） |
| `llvm@21` | 现代编译器基础设施（clang 等），C/C++ 等原生工具链的基础 | 41k | [!18194](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18194) |
| `lld@21` | LLVM 的链接器，链接速度快 | 同上 | [!18536](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18536) |
| `libsecret` | GNOME 的密钥存储库，不少 CLI 工具靠它安全保存密码和令牌 | — | [!18633](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18633) |
| `herdr` | 住在终端里的 Agent 复用器，一个界面管理多个 coding agent 会话 | 42k | [!18651](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18651)（[!20617](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/20617)、[!20719](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/20719)） |
| `starship` | 跨 shell 的极简、高度可定制的终端提示符 | 60k | [!18673](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18673)（[!18770](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/18770)） |
| `pnpm` | 快速、省磁盘的 Node 包管理器（v12 为 Rust 重写） | 37k | [!20806](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/20806) |
| `bun` | 集运行时、包管理、测试、打包于一体的极速 JavaScript 工具链 | 96k | [!21450](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/21450) |

上游 ⭐ 为 GitHub star 数（2026-10-02 取值）。

formula 成熟后合入官方 core，本 tap 随之下线自有版本。

## 尚未合入官方 core

本 tap 目前仍自行维护的 formula，进度一览：

| Formula | 状态 | 备注 |
|---|---|---|
| `opencode` | 审核中 [!21455](https://gitcode.com/Harmonybrew/homebrew-core/merge_requests/21455) | v2；合入后本 tap 的版本随之下线 |
| `opencode-v1` | 未提交 | v1 稳定版 |
| `claude-code` / `claude-code.latest` | 未提交 | 闭源，License 禁止再分发官方产物，只能安装时拉取官方二进制，不符合官方准入规则 |
| `zcode` | 未提交 | 上游不发 git tag，源码取自 main |
| `vite-plus` | 未提交 | — |
| `hishell-font` | 未提交 | — |
| `sshport` | 未提交 | — |
| `qemu-aarch64` | 未提交 | 基于 Alpine 预编译包，不符合官方准入规则 |
| `ohos-compat-shim` | 未提交 | — |

## 已迁移到官方 core

下列 formula 曾在本 tap 提供，现由官方 core 原生提供：`codex`、`cc-switch`、`reasonix`、`deepseek-harness`、`uv`、`codegraph`、`nvm`、`llvm@21`、`lld@21`、`ohos-bst-light`、`libsecret`、`zellij`、`herdr`、`starship`、`node-ohos`、`bun`。

已装本 tap 旧版的先 `brew uninstall social4hyq/core/<名>`，再 `brew install <名>`。三个特例：

- `cc-switch` 在官方 core 里叫 `cc-switch-cli`
- `node-ohos` 在官方 core 里叫 `node`
- `ohos-bst-light` 命令名变了：旧版装 `self-sign`，官方版装 `selfsign`（无连字符），参数不变，脚本里的调用要同步改

其余无官方替代的下线项和改名记录见 [docs/offline-history.md](docs/offline-history.md)。

## 已知限制

- **代码签名**：鸿蒙 PC 终端强制代码签名，本 tap 的产物已签名；自行编译或下载的 Linux 程序需自行签名，否则 `Permission denied`
- **系统调用差异**：缺失的 syscall、`getpwuid_r`、`splice` 唤醒等由 `ohos-compat-shim` 兜底，高并发 IO 吞吐略低于 Linux
- **文件系统**：沙箱内 `/tmp` 只读，临时文件走 `$TMPDIR`（需指向可写分区）；硬链接未开放，由 shim 降级为复制

平台放行后 shim 会自动切回原生实现。逐项说明见 [docs/known-limitations.md](docs/known-limitations.md)。

## 反馈与仓库

问题请到 [GitHub Issues](https://github.com/social4hyq/homebrew-core/issues) 反馈，附 HarmonyOS 版本、`<工具> --version`、复现命令。

本仓库以 GitHub 为唯一源头（源码、Issues、PR、CI）。[atomgit 同名仓库](https://atomgit.com/social4hyq/homebrew-core) 是单向镜像，只为国内更快下载 bottle，请勿向其推送代码或开 PR。

## 致谢

感谢 **hqzing**：其《鸿蒙 PC 底层开发技术详解》系列（代码签名机制、二进制自签名算法、问题定位手段）和开源的自签工具 `ohos-bst-light` 为本 tap 提供了重要参考，《鸿蒙 PC 上可用的 AI Agent 工具汇总》也推荐了本 tap 的 OpenCode 移植版。相关文章（CSDN）：

- 《鸿蒙 PC 底层开发技术详解（四）：代码签名机制对我们的影响》 — https://blog.csdn.net/hqzing/article/details/160746583
- 《鸿蒙 PC 底层开发技术详解（七）：二进制自签名算法的实现》 — https://blog.csdn.net/hqzing/article/details/162642397
- 《鸿蒙 PC 底层开发技术详解（八）：鸿蒙 PC 上的问题定位手段》 — https://blog.csdn.net/hqzing/article/details/163311519
- 《在鸿蒙 PC 上使用 Claude Code（最新的 Bun 版本）》 — https://blog.csdn.net/hqzing/article/details/162758675
