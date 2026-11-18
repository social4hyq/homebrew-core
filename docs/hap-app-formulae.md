# HAP 应用 formula 规范

本 tap 里以 HAP 形态交付的应用（`*-app`、`app-installer`）遵循以下约定。

## 目录

| 目录 | 放什么 |
|---|---|
| `Formula/<x>/<name>.rb` | formula，单文件自包含，不写 tap 级共享 Ruby |
| `Patches/<name>/` | 只放对上游源码或第三方 resource 打的 `*.patch` |
| `Resources/<name>/` | tap 自写的非补丁文件：`app/`（Electron 壳源码）、`assets/`（图标）、`scripts/`（启动器、`install-desktop.sh`、桥接脚本）、`hap/`（原生 HAP 工程模板）、`support/`（构建期辅助脚本）、`tests/`（`test do` 用的辅助文件） |
| `Resources/_shared/<group>/` | 多个 formula 共用、逐字节相同的文件（如 `electron-shell/tray.cjs`） |

不要把非补丁文件放进 `Patches/`。`remove-unused-patches` 逐文件判断引用，拼出来的路径（循环取文件、整目录拷贝）会被误判为未使用而删除。

## `remove-unused-patches` 对 `Resources/` 的判定

按目录整体保留，不逐文件判断：

- `Resources/<name>/`：`Formula/*/<name>.rb` 存在，且 formula 里出现字面串 `"Resources/<name>"`。
- `Resources/_shared/<group>/`：至少一个 formula 里出现字面串 `"Resources/_shared/<group>"`。
- 其余视为孤儿，周任务会开 PR 删除。

所以 formula 里必须有这样的字面写法（例如 `RESOURCE_FILES` 清单里的路径，或 `tap_root/"Resources/<name>"`），不能只靠运行时拼接出目录名。

## CI 触发

`pr-validate` 和 `publish-on-merge` 在 `Formula/**`、`Patches/**`、`Resources/**` 变化时触发。`detect-changes.sh` 把 `Patches/<name>/`、`Resources/<name>/` 的变化映射到 formula `<name>`，把 `Resources/_shared/<group>/` 的变化映射到所有引用它的 formula，这些 formula 一律重建（不适用 bottle-only、comment-only 的跳过）。

只改 `Patches/` 或 `Resources/`、不动上游版本时，同样要给 formula 的 `revision` 加 1（见 skill 的 own-tap 第 10 条）。

## Electron 壳 formula 骨架

底本是 `Formula/o/orca-app.rb`。段落顺序固定：

1. 头部：`desc / homepage / url / sha256 / license / revision / livecheck / bottle`
2. `depends_on`：`app-installer`、`node`、`ohos-sdk-toolchains`、`unzip`、`zip`、后端 formula（与官方 core 重名时写全限定名），app 专属依赖排最后
3. `resource "electron-ohos"`：各 formula 使用同一个版本 pin
4. `RESOURCE_FILES = %w[...]`：字面列出用到的每个文件；`install` 开头逐个检查，缺失就 `odie "missing tap resource: ..."`
5. `install`：解包并拷入壳文件 → 品牌（bundleName、vendor、图标、所有 `*/element/string.json`）→ 去签名配置、`extractNativeLibs`、收窄权限 → `windowStageClose` 拦截 → CLT 守卫与环境、rlimit → `ohpm install` + `hvigorw assembleHap` → `libexec` 放未签名 HAP、`pkgshare/module-acl.json` 放 ACL 版本 → 脚本用 `cp` + `chmod 0755`（不用 `Pathname#install`，CI 里 tap 只读）→ `write_env_script`
6. `caveats`：装机命令、子命令列表、ACL 与 `--no-acl` 的说明
7. `test do`：`HOME` 与 `XDG_CONFIG_HOME` 都指进 `testpath`；假的 `hdc` 和 `app-installer`；默认与 `--no-acl` 两种变体的权限集；`free_port` 下的 `status`/`stop`；真实 HAP 的 `unzip -l` 与内容断言

`multica-app`、`herdr-app`、`snow-shot-app` 的构建路径不同，只遵守目录约定和 `RESOURCE_FILES` 清单。

## 标识命名与历史例外

新 app 使用：bundle ID `com.social4hyq.<name>`，命令 `<name>-app`，环境变量前缀 `<NAME>_DESKTOP_`，状态目录 `~/.config/<name>-app`。

已发布的 app 不改标识（改 bundle ID 会丢失已装应用沙箱里的数据，改状态目录需要迁移），现状如下：

| formula | bundle ID | 状态目录 | 环境变量前缀 |
|---|---|---|---|
| opencode-app | `com.social4hyq.opencodedesktop` | `~/.config/opencode-desktop` | `OPENCODE_DESKTOP_` |
| orca-app | `com.social4hyq.orca` | `~/.config/orca-app` | `ORCA_DESKTOP_` |
| zcode-app | `com.social4hyq.zcodedesktop` | `~/.config/zcode-desktop` | `ZCODE_DESKTOP_` |
| deepseek-harness-app | `com.social4hyq.deepseekharness` | `~/.config/deepseek-harness-desktop` | `DSH_DESKTOP_`、`DSH_APP_` |
| magpie-app | `com.social4hyq.magpiedesktop` | — | `MAGPIE_APP_` |
| obsidian-app | `com.social4hyq.obsidiandesktop` | — | `OBSIDIAN_DESKTOP_` |

## 迁移检查清单（`Patches/<name>` → `Resources/<name>`）

1. `git mv` 非补丁文件到 `Resources/<name>/`，`.patch` 留在 `Patches/<name>/`
2. formula 里加 `RESOURCE_FILES` 字面清单和存在性检查，路径改成 `Resources/<name>/...`
3. `DRY_RUN=1 .github/scripts/remove-unused-patches.sh` 无误报
4. 新旧 bottle 的 HAP 逐文件比对 sha256；内容无变化则不加 `revision`
