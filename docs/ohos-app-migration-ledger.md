# HAP 桌面应用迁移台账（PR 0a 产物）

本文是 `docs/ohos-app-refactor-plan.md` PR 0a 的迁移台账，基于 tap 当前 `main`（`2bfe8cfcd9`）逐 formula 核实。每行一个逻辑应用，迁移时按 `docs/ohos-app-refactor-plan.md` 的 PR 拆分执行。

**目标分类**（决定归入哪个 PR）：
- **无插件**（纯 descriptor，PR 6a/6b）：无宿主后端、无厂商下载、无配对。
- **厂商装配**（PR 7a/7b）：安装期下载第三方包并装配。
- **宿主/配对**（PR 8b）：有宿主 daemon/bridge 或配对 token 注入。
- **特例**：私有镜像例外、tap 自造同名 CLI，单列风险。

## 17 行台账

| 目标 formula | 当前 formula | 上游 CLI 归属 | 宿主后端 | 厂商下载 | 私有镜像 | ACL 变体 | 安装脚本类型 | 分类 / 目标 PR |
|---|---|---|---|---|---|---|---|---|
| `antigravity-desktop` | `antigravity-app` | 无上游 CLI；`antigravity-app`=tap 包装器 | 宿主引擎 language-server.bin（无独立公式） | ✓ Google tar.gz ~204MB | electron-ohos-ci | ✓ module-acl.json | 共享 install-lib.sh + 专属脚本 | 厂商装配 / PR 7b |
| `antigravity-ide-desktop` | `antigravity-ide-app` | 无上游 CLI；包装器 | IDE 树注入 HAP（无独立 daemon） | ✓ Google IDE tar.gz ~194MB | electron-ohos-ci | ✓ module-acl.json | 共享 install-lib.sh + 专属脚本 | 厂商装配 / PR 7b |
| `brewo-desktop` | `brewo-app` | 无上游 CLI；`brewo-app`=自造安装包装器，**另有 `brewo-host`** | ✓ harbor-app 依赖 + brewo-host.py 桥 | ✗ | electron-ohos-clt 守卫 | 仅权限断言，无 ACL 变体 | formula heredoc（不引共享库） | 宿主/注册 / PR 8b；**唯一有 `service do` 块** |
| `bruno-desktop` | `bruno-app` | 上游有 `bruno` CLI 但 formula 未安装；包装器 | ✗ vendor asar 注入，弱沙箱 | ✓ GitHub .deb ~130MB | electron-ohos-ci | ✓ module-acl.json + 粘贴板权限 | 共享 install-lib.sh | 厂商装配 / PR 7b |
| `claude-code-desktop` | `claude-code-app` | ✓ `claude`（claude-code.latest） | ✓ claude-launch-bridge.cjs | ✓ Anthropic .deb | electron-ohos-ci | 仅权限断言，无 ACL 变体 | 自带脚本 + 自写 sha256 校验（不引共享库） | 厂商装配+宿主 / PR 7b |
| `codex-desktop` | `codex-app` | ✓ `codex` | ✓ owl-codex-bridge / owl-pty-host | ✓ OpenAI .deb ~519MB | electron-ohos-ci | ✓ module-acl.json + --no-acl | 共享 install-lib.sh | 厂商装配+宿主 / PR 7b |
| `deepseek-harness-desktop` | `deepseek-harness-app` | ✓ `dsh` | ✓ dsh web（serve/status/stop） | ✗ | electron-ohos-ci | ✓ module-acl.json + --no-acl | formula 内生成 + 共享库（混合） | 宿主 / PR 8b（原计划漏列） |
| `genoffice-desktop` | `genoffice-app` | ✓ `genoffice` | ✗ CLI + sidecar 内嵌，无 daemon | ✗ | electron-ohos-ci | ✓ module-acl.json + --no-acl | 自带脚本 + 共享库 | 无插件试点 / PR 6a |
| `harbor-desktop` | `harbor-app` | ✓ `harbor`（bin.install） | ✗ 自身即服务管理器 | ✗ | electron-ohos-clt 守卫 | 仅权限断言，无 ACL 变体 | formula heredoc（不引共享库） | 无插件 / PR 6b；**CLI 随公式安装，迁移须保证透明** |
| `herdr-desktop` | `herdr-app` | ✓ `hc`（herdr-core） | ✓✓ herdr-bridge.py 回环令牌桥 | ✗ | electron-ohos-ci | 仅权限断言 + PermissionPlugin | 自带脚本（不引共享库） | 宿主/配对 / PR 8b |
| `magpie-desktop` | `magpie-app` | ✓ `magpie` | ✓ magpie 宿主后端 | ✗ | electron-ohos-ci | ✓ module-acl.json + --no-acl | 共享 install-lib.sh | 宿主 / PR 8b（原计划漏列） |
| `multica-desktop` | `multica-app` | ✓ `multica` | ✓✓ Go bridge 回环 HTTP+Bearer | ✗ | electron-ohos-ci | ✓ module-acl.json + --no-acl | 共享 install-lib.sh + 上游 dispatch | 宿主/配对 / PR 8b |
| `obsidian-desktop` | `obsidian-app` | **tap 自造同名 CLI `obsidian`**（对齐上游 obsidian.md/cli）；另 `obsidian-app` | 部分：HAP 沙箱 socket 桥 | ✓ 官方 asar.gz | electron-ohos-ci | ✓ module-acl.json + --no-acl | 共享 install-lib.sh + 自造 CLI 脚本 | 厂商装配 / PR 7b；**CLI 自造，迁移须核对上游** |
| `opencode-desktop` | `opencode-app` | ✓ `opencode` | ✓ opencode serve | ✗ | electron-ohos-ci | ✓ module-acl.json + --no-acl | 共享 install-lib.sh | 宿主 / PR 8b（原计划漏列） |
| `orca-desktop` | `orca-app` | ✓ `orca` | ✓ orca serve（orcad） | ✗ | electron-ohos-ci | ✓ module-acl.json + --no-acl | 共享 install-lib.sh | 宿主 / PR 8b（原计划漏列） |
| `snow-shot-desktop` | `snow-shot-app` | **tap 自造同名 CLI `snow-shot`**（symlink→安装包装器）；上游为 Qt GUI，无 CLI | ✗ 原生 Qt HAP 自包含 | ✗（OCR/Qt 为构建期 resource） | **qt-ohos-ci 例外**（不受 OHOS_CI_IMAGE_OVERRIDES 控制） | 仅注入权限，无 ACL 变体 | 自带 snow-shot-install.sh（不引共享库） | 无插件 / PR 6b；**私有镜像例外 + 自造 CLI 双风险** |
| `zcode-desktop` | `zcode-app` | ✓ `zcode` | ✓✓ zcode app-server --stdio + token | ✗ | electron-ohos-ci | ✓ module-acl.json + --no-acl | 共享 install-lib.sh | 宿主 / PR 8b（原计划漏列） |

## 关键事实（影响 PR 拆分）

1. **唯一 `service do` 块**：`brewo-app`（L99-107）。迁移为显式服务，须单独验收。
2. **tap 自造同名 CLI 两个**：`snow-shot`（指向安装包装器）、`obsidian`（tap 自研 CLI 客户端）。这是"回归上游 CLI"原则下的重点整改对象——须核对上游真实 CLI，不能把包装器当上游。
3. **安装期厂商下载 6 个**（非 3 个）：antigravity、antigravity-ide、bruno、claude-code、codex、obsidian。统一走 `sources.lock.json` + 通用 fetcher。
4. **私有镜像例外**：`snow-shot-app` 用 `qt-ohos-ci`（`/opt/qt-ohos/qt-6.13.0-dev`），不走 `OHOS_CI_IMAGE_OVERRIDES`；PR 0b 的私有镜像配置必须单独为它建 entry。
5. **ACL 变体**：12 个有 `module-acl.json`（其中 10 个支持 `--no-acl`）；brewo/harbor/herdr/claude-code 仅做权限断言无变体；snow-shot 注入权限但无变体。descriptor 的 `variants` 按此填写，无变体者只声明 `basic`。
6. **共享 vs 自带脚本**：11 个共享 `install-lib.sh`；自带 6 个（brewo、claude-code、harbor、herdr、snow-shot，外加 deepseek 混合型）。自带者迁移时直接换 descriptor + 专属插件，无需保留 shell 库。
7. **宿主后端强度**：强依赖（multica Go bridge、herdr 令牌桥、codex/obsidian/zcode 桥+token）放 PR 8b，必须在全新环境首次启动、token 跨升级真机矩阵通过后才迁。

## 迁移执行顺序（由台账推导）

- PR 6a：`genoffice-desktop`（无插件试点，验证最薄链路）。
- PR 7b：厂商装配类 6 个（先 codex 验证 `sources.lock.json` + fetcher）。
- PR 8b：宿主/配对类，按依赖强度递增；multica/herdr 最后。
- PR 6b：其余无插件/简单类（harbor、snow-shot、deepseek、magpie、opencode、orca、zcode 中未归入 8b 者）——注意 harbor 须保 CLI 透明、snow-shot 须处理私有镜像例外。

每迁移一行：勾选本行、删除对应旧 `*-app` formula 与 `post_install_steps`、加入 descriptor/专属插件、按实际产物变化检查 revision、style/audit/readall 全绿、bottle pour + 真机冒烟。
