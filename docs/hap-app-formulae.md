# HAP 桌面应用 formula 规范

本 tap 以 HAP 形态交付的桌面应用（`*-desktop`）遵循以下约定。架构和验收合同见 [ohos-app-refactor-plan.md](ohos-app-refactor-plan.md)，本文是日常维护规范。

## 交付模型

`brew install <name>-desktop` **只交付文件**：一个未签名 HAP、一份 `app.json` descriptor、ACL 版本清单。它不访问设备、不登录、不弹安装器、不启动服务、不改宿主配置。部署是显式动作：

```
ohos-app install <name>-desktop
```

没有 `post_install` 自动装机、没有 pending 队列、没有自动登录、没有后台补装进程。安装失败返回非零，由调用方决定如何处理。

## 三个公开命令

tap 自有的公开命令只有三个，各自职责单一，通过版本化的 L0 进程协议通信：

| 命令 | 职责 |
|---|---|
| `ohos-app` | 编排：发现 descriptor，驱动签名与设备部署 |
| `ohos-hap` | 签名 / 验证 / inspect HAP |
| `ohos-device` | 设备操作（hdc / sideload）、安装状态与生命周期 |

上游 CLI（如 `codex`、`opencode`、`claude-code`）是独立 formula，不属于这三个命令，也不被它们占用或包装。`ohos-app` 不实现签名、设备 I/O、装配或宿主服务管理；需要个性化或组装的 app 通过 descriptor 声明 Node 插件，由 `ohos-app install` 按 personalization → assembly → sign → device 的顺序编排。插件不回调任何 `<app> install` 命令。

`ohos-app` 的接口：

```
ohos-app list [--json]
ohos-app info <id> [--json]
ohos-app configure <id>
ohos-app install <id> [--device SEL] [--variant NAME] [--signing-profile NAME]
               [--method hdc|sideload|auto] [--start] [--json]
ohos-app uninstall <id> [--device SEL] [--purge]
ohos-app start|stop|status <id> [--device SEL] [--json]
ohos-app logs <id> [--device SEL]
ohos-app doctor [<id>] [--json]
ohos-app cache list|prune
```

descriptor 从 `$HOMEBREW_PREFIX/opt/*/share/*/ohos/app.json` 发现，没有中央注册表。`uninstall` 默认保留设备数据，`--purge` 只清设备沙箱数据。

## 目录

| 目录 | 放什么 |
|---|---|
| `Formula/<x>/<name>-desktop.rb` | formula，单文件自包含，不写 tap 级共享 Ruby |
| `Patches/<name>-desktop/` | 只放对上游源码或第三方 resource 打的 `*.patch` |
| `Resources/<name>-desktop/` | tap 自写的非补丁文件：`app/`（Electron 壳源码）、`assets/`（图标）、`tests/`（`test do` 用的辅助文件）、`app.json.in`（descriptor 模板） |
| `Resources/_shared/<group>/` | 多个 formula 共用、逐字节相同的文件（如 `waiting-page/`） |

不要把非补丁文件放进 `Patches/`。`remove-unused-patches` 逐文件判断引用，拼出来的路径（循环取文件、整目录拷贝）会被误判为未使用而删除。

## `remove-unused-patches` 对 `Resources/` 的判定

按目录整体保留，不逐文件判断：

- `Resources/<name>/`：`Formula/*/<name>.rb` 存在，且 formula 里出现字面串 `"Resources/<name>"`。
- `Resources/_shared/<group>/`：至少一个 formula 里出现字面串 `"Resources/_shared/<group>"`。
- 其余视为孤儿，周任务会开 PR 删除。

所以 formula 里必须有这样的字面写法（例如 `RESOURCE_FILES` 清单里的路径，或 `tap_root/"Resources/<name>"`），不能只靠运行时拼接出目录名。

## CI 触发

`pr-validate` 和 `publish-on-merge` 在 `Formula/**`、`Patches/**`、`Resources/**` 变化时触发。`detect-changes.sh` 把 `Patches/<name>/`、`Resources/<name>/` 的变化映射到 formula `<name>`，把 `Resources/_shared/<group>/` 的变化映射到所有引用它的 formula，这些 formula 一律重建（不适用 bottle-only、comment-only 的跳过）。

只改 `Patches/` 或 `Resources/`、不动上游版本时，同样要给 formula 的 `revision` 加 1。

## Electron 壳 formula 骨架

底本是 `Formula/g/genoffice-desktop.rb`。段落顺序固定：

1. 头部：`desc / homepage / url / sha256 / license / livecheck / bottle`
2. `depends_on`：上游 CLI（与官方 core 重名时写全限定名）、`node`、`ohos-sdk-toolchains`、`unzip`、`zip`
3. `resource "electron-ohos"`：所有 formula 使用同一个版本 pin
4. `patch` 块：遍历 `Patches/<name>-desktop/ohos/*.patch` 动态挂载
5. `RESOURCE_FILES = %w[...]`：字面列出用到的每个文件；`install` 开头逐个检查，缺失就 `odie "missing tap resource: ..."`
6. `install`：解包并拷入壳文件 → 品牌（bundleName、vendor、图标、`*/element/string.json`）→ 去签名配置、`extractNativeLibs`、收窄权限 → `windowStageClose` 拦截 → CLT 守卫与环境、rlimit → `ohpm install` + `hvigorw assembleHap` → `libexec` 放未签名 HAP、`pkgshare/module-acl.json` 放 ACL 版本 → 渲染等待页 → 写 `pkgshare/ohos/app.json` descriptor
7. `test do`：校验 descriptor（schema/id/sha256/bundle_id/variant）、HAP 内容、壳源码语法与 node 测试；不访问设备

脚本用 `cp` + `chmod 0755`，不用 `Pathname#install`（CI 里 tap 只读）。

CLT 私有路径（`/opt/electron-ohos-clt`）由 CI 镜像提供，formula 只校验其存在并在缺失时 `odie`，不改 PATH 去猜。

## descriptor（`app.json`）

`install` 生成 `pkgshare/ohos/app.json`，由 `ohos-app` 发现。关键字段：

- `schema_version`：1
- `id`：`social4hyq/core/<name>-desktop`
- `artifact`：`format: hap`、`path`、`sha256`、`api`、`abis`、`bundle_id`、`version_name`、`version_code`
- `launch`：`module`、`ability`
- `variants`：`default` 与 `definitions`（`basic` / `acl`，acl 带 `module_overlay` 与其 sha256）
- `signing_profile`：可选，指定该 app 默认使用的 `ohos-hap` 逻辑 profile；CLI 的 `--signing-profile` 优先级更高。
- `personalization` / `assembly`：可选的 keg 内 Node 插件路径。`ohos-app install` 为本次安装创建私有 staging，先运行 personalizer（传入非秘密 HOME/PATH/XDG），再运行 assembler（传入所选 variant、已校验的 overlay 路径和 personalizer 输出），最后走统一签名与设备部署。无插件的现有 descriptor 保持直接签名 unsigned HAP 的行为。

`test do` 必须核对 descriptor 的 sha256 与实际 HAP 一致，防止描述与交付物漂移。

## 共享的等待页（`waiting.html`）

Electron 壳启动时先显示的等待页，由一份模板加每个 app 的文案在构建时生成：

- `Resources/_shared/waiting-page/waiting.html.in`：模板，占位符 `{{name}}`、`{{command}}`、`{{subtitle}}`、`{{accent}}`、`{{wash}}`、`{{washDark}}`。
- `Resources/_shared/waiting-page/render-waiting.cjs`：渲染器（node）。严格：占位符缺值、值没被用到、值里带 `< > & ' " \` 或换行或 `{{`、占位符格式不对，都是错误。
- `Resources/<app>/app/waiting.json`：每个 app 的文案（名字、命令、副标题、三个颜色）。
- formula 在 `install` 里调用渲染器，输出到 HAP 的 `app/waiting.html`，并把渲染器、模板和 `waiting.json` 列进 `RESOURCE_FILES`。

文案改动直接体现在 `waiting.json` 的 diff 里，由 code review 把关；不锁定渲染结果的哈希。

## CI 检查

`pr-validate` 的 `hap-checks` job 不依赖 `detect`，在构建之前几秒内跑完，失败时不进入构建：

- `.github/scripts/check-hap-formulae.py`：有 `Resources/<name>/` 的 formula 必须有字面 `RESOURCE_FILES`，清单与目录文件逐项一致、路径都存在，并有 `odie "missing tap resource"` 检查；所有 formula 的 `electron-ohos` 版本（url 与 sha256）一致；从 tap 取文件不能用 `.install`（只能 `cp`）。
- `.github/scripts/test-detect-changes.sh`：变更检测的单元测试。
- `.github/scripts/test-waiting-page.sh`：渲染每个用到共享等待页的 app，并检查渲染器严格性。

本机运行：`python3 .github/scripts/check-hap-formulae.py`、`.github/scripts/test-detect-changes.sh`、`.github/scripts/test-waiting-page.sh`（需要 bash、node）。

源码构建与 bottle 发布在 CI 容器内进行；本机 `--build-from-source` / `--build-bottle` 被禁用，只能跑 `brew readall` / `style` / `audit`。

## 标识命名与历史例外

新 app 使用：bundle ID `com.social4hyq.<name>`，formula 名 `<name>-desktop`。bundle ID 保持不变（改它会导致已装应用丢沙箱数据）。已发布的 app 沿用既有 bundle ID，见各 formula 的 descriptor。

## 迁移检查清单（`Patches/<name>` → `Resources/<name>`）

1. `git mv` 非补丁文件到 `Resources/<name>/`，`.patch` 留在 `Patches/<name>/`
2. formula 里加 `RESOURCE_FILES` 字面清单和存在性检查，路径改成 `Resources/<name>/...`
3. `DRY_RUN=1 .github/scripts/remove-unused-patches.sh` 无误报
4. 新旧 bottle 的 HAP 逐文件比对 sha256；内容无变化则不加 `revision`
