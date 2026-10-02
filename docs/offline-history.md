# 下线 / 改名历史

本 tap 已下线 formula 与改名的存档。仍需用户操作的迁移（改由 Harmonybrew 官方 core 提供）见 [README 的「已迁移到官方 core」](../README.md#已迁移到-harmonybrew-官方-core)；本文只留历史记录，被删除的 formula 都保留在 tap git 历史中，可从历史恢复。

## 已下线（无官方替代）

| Formula | 下线日期 | 原因 |
|---|---|---|
| `opencode-shim` / `opencode-shim@2` | 2026-08-02 | 预编译 shim 路线已被源码构建路线取代，改用 `opencode-v1` / `social4hyq/core/opencode` |
| `close-range-shim` | 2026-07-15 | 功能并入 `ohos-compat-shim` |
| `bun-pty` / `lightningcss` / `tailwindcss-oxide` | 2026-07-18 | 改走 `@ohos-ports/*` npm 包，无独立 formula 需求 |
| `icu4c@78` | 2026-08-09 | libc++ ABI `__n1` 迁移（#239-#241）后本 tap fork 冗余，直接用上游 harmonybrew/core 的 `icu4c@78`（同为 `__n1`） |
| `grok-build` | 2026-08-12 | 已停止维护（使用率低） |
| `warp-tui` | 2026-08-12 | 已停止维护（使用率低） |
| `inject-runpath` / `dlopen-sign-shim` | 2026-08-12 | 已无 formula 依赖（原用途已被预签名 npm `.so` + bun r31 起静态内嵌的 `ohos-compat-shim` 取代） |
| `nvm-ohos` | 2026-08-15 | 旧实现存档：`NVM_INSTALL_THIRD_PARTY_HOOK` 重定向 `nvm install` 到 brew node keg；继任者 `nvm` 也已迁移到官方 core |
| `zig@0.15` | 2026-09-04 | 唯一消费者 herdr 已改为 install() 内联官方预编译 zig（resource 下载 + binary-sign-tool 签名），独立 keg 无保留必要 |
| `bun-webkit` / `bun-bootstrap` | 2026-09-18 | 随 bun 1.4 切换「上游源码 + 补丁」构建（2026-09-12），`bun.rb` 不再依赖独立 WebKit 组件 formula 与预编译引导包，二者失去唯一消费者；`Patches/bun-webkit/` 一并删除 |
| `bun-legacy` | 2026-10-02 | 原 `bun` 的 fork 直构存档（113 个按文件补丁，`keg_only`）；随 `bun` 迁移到官方 core 一并删除，无替代 |

## 已迁移到官方 core 的下线日期

| Formula | 下线日期 |
|---|---|
| `codex` | 2026-07-23 |
| `cc-switch`（官方名 `cc-switch-cli`） | 2026-08-12 |
| `reasonix` | 2026-08-12 |
| `deepseek-harness`（官方版含 link 兜底 / 凭据模式 / ripgrep 回退 / crypto polyfill / 无沙箱放行 OHOS 补丁集） | 2026-08-15 |
| `uv`（官方版含全部三个 OHOS 补丁与 wheel 自动签名） | 2026-08-20 |
| `codegraph`（无补丁单文件） | 2026-08-24 |
| `nvm`（0.40.7，OHOS 平台补丁 + ohos-node.com 发行源） | 2026-08-24 |
| `llvm@21` / `lld@21` | 2026-09-08 |
| `ohos-bst-light` | 2026-09-08 |
| `libsecret` | 2026-09-08 |
| `zellij` | 2026-09-08 |
| `herdr` | 2026-09-08 |
| `starship` | 2026-09-09 |
| `node-ohos`（官方 `node` 已改用 `llvm@22` 重编，原生 OHOS 支持，26.8.1；本 tap 停留在 `llvm@21` / 26.7.0） | 2026-09-09 |
| `bun` | 2026-10-02 |

## 改名

- **2026-08-01**：`ohos-opencode` → `opencode`、`ohos-opencode@2` → `opencode@2`（命令名同步改为 `opencode` / `opencode2`）。bottle 不随改名自动迁移，已装旧名的用户请先 `brew uninstall <旧名>` 再 `brew install <新名>`。
- **2026-09-22**：`opencode@2` 更名为 `opencode-v2`（对齐上游官方 formula 名，`formula_renames.json` 自动迁移已装用户），并对齐上游的**原位替代**语义——命令名从 `opencode2` 改回 `opencode`，新增 `conflicts_with "opencode"`（与 v1 不能同时安装），数据目录从独立的 `~/.config/opencode2` 等改回与 v1 共享的 `~/.config/opencode`（v1 的数据库会被 v2 自动迁移）。旧版遗留的 `~/.config/opencode2`、`~/.local/share/opencode2`、`~/.local/state/opencode2` 目录升级后可手动删除。
- **随后**：`opencode` 由 v2 接管，v1 保留为 `opencode-v1`；`opencode-v2` 与 `opencode@2` 经 `formula_renames.json` 自动迁移到 `opencode`。
