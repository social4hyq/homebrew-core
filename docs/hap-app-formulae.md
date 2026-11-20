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

## CLI 约定

每个桌面 app 的命令是 `<name>-app`（已发布的 app 同时保留 `<name>-desktop` 符号链接），子命令：

| 子命令 | 作用 |
|---|---|
| `install` | 往 HAP 的副本里注入本机配置，签名并安装 |
| `start` / `stop` / `status` | 打开应用、停止、查看状态（有宿主后端的 app 同时管理后端） |
| `serve` | 只启动宿主后端（浏览器或 CLI 使用） |

`install` 的选项：`--hap PATH`、`--config PATH`、`--device ID`、`--no-acl`、`--keep`。约定：结果行（`installed (<bundle>, <variant>)`）写 stdout，进度和错误写 stderr，这样 `brew test` 和调用方可以只读 stdout。

wrapper（`write_env_script`）的环境变量统一用 `<PREFIX>_` 加这些后缀：`UNSIGNED_HAP`、`INSTALL_SCRIPT`、`MODULE_ACL`、`HDC_DEFAULT`、`<BACKEND>_BIN`，另有可覆盖的 `BUNDLE`、`APP_NAME`、`HDC`。前缀见下面的历史例外表。

## `brew install` 后自动装机

每个 HAP app 的 formula 在 `install` 之后、`caveats` 之前声明一步 post-install：

```ruby
post_install_steps do
  run "{{HOMEBREW_PREFIX}}/bin/hap-app",
      args: ["auto-install", "orca-app", "com.social4hyq.orca"],
      must_succeed: false, print_stdout: true, network_access: true
end
```

`hap-app` 由 `app-installer` 提供（所有 app 都依赖它）。Homebrew 在 link 之后执行
`post_install_steps`，bottle 安装与 `brew upgrade` 都会走；`--build-bottle` 与
`--skip-post-install` 会跳过，所以 CI 构建不会碰设备。**不要用 `def post_install`**：
`brew style` 的 `InstallSteps` cop 已禁止，必须用 `post_install_steps`。

行为：

- 设备已连接、华为开发者已登录：立刻签名安装，装完用 `bm dump` 校验权限；
  stdout 一行结果，stderr 是进度。
- 设备没连、多个设备、没登录、装机失败、权限未授予：不报错、不阻塞 brew，
  把 `<command>` 登记到 `$XDG_CONFIG_HOME/hap-app/pending/<command>.json`，
  提示运行 `hap-app install-pending`；登录只做一次。
- 自动路径**不启动** app（`HAP_INSTALLER_NO_START=1` 传给 app-installer），
  也不弹登录（除非 `HAP_APP_AUTO_LOGIN=1`，最多等 120s，每次 brew 进程只试一次）。
- 手动 `<app>-app install` 行为不变：仍会启动 app、仍会阻塞登录。
- 权限：自动路径永远用默认 ACL 变体，不传 `--no-acl`；`hap-app` 从 app wrapper
  的 `*_MODULE_ACL` 取 ACL 清单传给 `app-installer permissions --expect-acl`，
  既确认装的是 ACL 变体，也只要求 `system_grant`（安装时授予）的权限为 granted；
  `user_grant` 权限（粘贴、截屏等）装机后是 -1，只报告不判失败。
- CI、root、`HAP_APP_AUTO_INSTALL=0`（或配置文件
  `$XDG_CONFIG_HOME/hap-app/config` 里 `auto_install=0`）下静默 no-op。
- 逃生口：`brew install --skip-post-install`；补跑用 `brew postinstall <app>`。

`hap-app` 子命令：`auto-install`（formula 用）、`install-pending`、`status`、
`forget`。`app-installer` 另有 `ready`（无副作用预检，输出 `ok <device>` /
`no-device` / `no-login` / `no-hdc` / `multiple-devices`）、`login`、
`permissions`。

## 共享安装库

`Resources/_shared/hap-app/install-lib.sh` 是 Electron 壳 app 共用的安装流程：解析参数、检查工具、ACL 的 `module.json` 与 HAP 的 bundle 一致性预检、暂存目录、把要注入的文件加进 HAP 副本、流式调用 `app-installer`、`--keep`、结果行。formula 把它 `cp` 到 `pkgshare/"hap-app-install-lib.sh"`，与每个 app 自己的薄脚本 `install-desktop.sh` 放在同一目录，薄脚本 `source` 它。

薄脚本设置 `APP_CMD`、`ENV_PREFIX`、`BUNDLE_ID_DEFAULT`、`APP_NAME_DEFAULT`，并定义 `stage_tree CONFIG TREE`（把要放进 HAP 的文件写到 `TREE` 下，路径与 HAP 根一致）；可选的 `NEED_CONFIG`、`EXTRA_TOOLS`、`KEEP_BASENAME`、`MODULE`、`ABILITY`、`app_usage_extra`、`app_parse_option`、`app_prepare` 见库文件头部的注释。库的行为由 `.github/scripts/test-hap-install-lib.sh` 独立测试，改库前先跑它。

注意：`Resources/_shared/hap-app/` 的任何改动会让所有引用它的 formula 重建，所以库要少改。

## 共享的等待页（`waiting.html`）

Electron 壳启动时先显示的等待页，各 app 之前各存一份，现在由一份模板加每个 app 的文案在构建时生成：

- `Resources/_shared/waiting-page/waiting.html.in`：模板，占位符 `{{name}}`、`{{command}}`、`{{subtitle}}`、`{{accent}}`、`{{wash}}`、`{{washDark}}`。
- `Resources/_shared/waiting-page/render-waiting.cjs`：渲染器（node）。它是严格的：占位符缺值、值没被用到、值里带 `< > & ' " \` 或换行或 `{{`、占位符格式不对，都是错误。
- `Resources/<app>/app/waiting.json`：每个 app 的文案（名字、命令、副标题、三个颜色）。
- formula 在 `install` 里调用渲染器，输出到 HAP 的 `app/waiting.html`，并把渲染器、模板和 `waiting.json` 列进 `RESOURCE_FILES`。
- `Resources/_shared/waiting-page/expected.sha256` 固定每个 app 渲染结果的 sha256（迁移时等于被替换的原页面）。要有意改某个页面，就在同一个 PR 里更新这里的哈希；`test-waiting-page.sh` 会在 `hap-checks` 里检查，所以页面不会被悄悄改掉。

## CI 检查

`pr-validate` 里的 `hap-checks` job 不依赖 `detect`，在构建之前几秒内跑完，失败时不会进入构建：

- `.github/scripts/check-hap-formulae.py`：有 `Resources/<name>/` 的 formula 必须有字面 `RESOURCE_FILES`，清单与目录里的文件逐项一致，清单里的路径都存在，并有 `odie "missing tap resource"` 检查；所有 formula 的 `electron-ohos` 版本（url 与 sha256）一致；从 tap 取文件不能用 `.install`（只能 `cp`）。
- `.github/scripts/test-hap-install-lib.sh`：用假的 `app-installer` 和现做的最小 HAP 测共享安装库。
- `.github/scripts/test-waiting-page.sh`：渲染每个用到共享等待页的 app，结果必须等于 `expected.sha256` 里固定的哈希，并检查渲染器的严格性。

本机运行：`python3 .github/scripts/check-hap-formulae.py`、`.github/scripts/test-hap-install-lib.sh`（需要 bash、node、zip、unzip）。

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
