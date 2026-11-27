# HAP 桌面应用交付架构清场重构：可执行改造计划

本文档是 `social4hyq/homebrew-core` tap 中 HAP 桌面应用（`*-app` / `app-installer` / `hap-app`）交付架构的**清场重构权威计划**。它综合了四轮对抗性复核（初步分析 → 激进重构 → 可行性反弹 → 清场设计）与侧载适配性研究的最终结论，给出从零开始的理想目标架构、命名体系、协议、按组件/PR 拆分的实施步骤、验证命令和验收脚本骨架。

CLAUDE.md 只留导航到此；本文件维护全部细节。所有结论基于 tap 当前 `main`（复核基线 `2bfe8cfcd9`）与 2026-11-05 华为官宣的鸿蒙 PC 年内侧载。

**前置声明**：本计划的前提是用户明确的清场指令——**不考虑现有 formula 兼容性、不做 rename/别名/迁移映射、直接改为最合适的设计、全面对标业界最佳实践、全面解耦方便维护**。因此不设弃用期、不建 `formula_renames.json` 映射、不做新旧双栈，在集成分支一次性切换发布。若该前提变化，回到 `docs/harmonybrew-tap.md` 与 `docs/hap-app-formulae.md`（旧架构说明）重新评估。

---

## 1. 最终决断（不可动摇的边界）

| 问题 | 最终选择 |
|---|---|
| 公开命令 | **三个：`ohos-app` / `ohos-hap` / `ohos-device`**；不设 `ohos-dev`，无旧名别名 |
| 应用包命名 | 桌面 HAP 一律 `<name>-desktop`；上游 CLI 包仍用上游名，二者分包 |
| descriptor id | 用 canonical formula 全名（如 `social4hyq/core/codex-desktop`），不另造编号 |
| 应用命令 | 只交付上游真实 CLI；没有官方 CLI 就不制造任何 `<name>-app/desktop` 命令 |
| `post_install` 自动装机 | **彻底删除**（连 opt-in 也不要）。`brew install/upgrade` 永远不访问设备、登录、启动服务 |
| pending 队列 / 自动补装 | **彻底删除**。部署同步、显式、失败即非零 |
| 登录 token | `ohos-app` 不保存；签名认证归 `ohos-hap` + 厂商凭据设施 |
| 通用引擎 ↔ app 扩展 | 版本化 manifest + 独立进程插件；禁 `source`、禁回调、禁安装后常驻 |
| 宿主 bridge/daemon | 由上游 CLI 或 brew services 管；安装/签名/设备启动均不隐式管理 |
| 侧载安装后端 | 归 `ohos-device` L4；`--method auto\|hdc\|sideload`，规范未公布前 fail-closed |
| 切换方式 | 集成分支建设，一次性切换发布；无双栈/映射/交叉兼容 |

**一句话边界**：Homebrew 交付不可变文件，`ohos-app` 编排显式应用部署，`ohos-hap` 只签名，`ohos-device` 只操作设备，上游 CLI 只管应用本身。

---

## 2. 目标架构

### 2.1 依赖方向

```
上游应用层    上游 CLI 透明 exec；宿主 daemon/bridge 由上游 CLI 或 brew services 管
     ↑ 不允许被安装器反向编排
L1 交付层     formula/bottle：unsigned HAP + app.json + sources.lock + 插件
     │ 稳定 opt 路径 + 不可变 manifest
     ↓
L5 编排层     ohos-app：解析应用、选变体、装配个性化、调用签名与设备合同
     ↓                ↓                 ↓
L2 制品配置   L3 签名 ohos-hap      L4 设备 ohos-device（多后端：hdc / sideload）
fetch/assemble  profile/keystore     hdc/bm/aa / 系统安装器 + 用户确认
内容寻址缓存    secret ref/sign      签后 HAP、后置核验、交互式安装状态

L0 合同层（贯穿）：JSON Schema / 进程协议 / 错误码 / secret 引用 / 安装后端状态
旁路：ohos-app configure <id> → host-integration 插件 → 只写配置不碰设备
```

### 2.2 各层可替换边界

| 层 | 输入 → 输出 | 明确禁止 | 独立测试方式 |
|---|---|---|---|
| L0 合同 | schema、协议主版本、能力集 | 应用名特判、shell 字符串协议 | JSON Schema、golden request/response、跨实现合同测试 |
| L1 交付 | 上游源码/制品 → bottle 内不可变文件 | 登录、写真实 HOME、设备操作、启动服务 | bottle 内容断言、断网 pour |
| L2 制品配置 | 已校验输入 + 纯配置 → unsigned HAP | 设备、签名、宿主服务、隐式网络 | fake 输入、确定性 golden HAP、缓存键测试 |
| L3 签名 | SigningRequest → signed HAP + 验证报告 | hdc/bm/aa、descriptor、宿主配置 | fake signer、真实测试证书、密码泄漏测试 |
| L4 设备 | signed HAP/bundle → 设备后置状态 | 签名、厂商下载、装配、宿主 daemon | fake hdc + fake sideload、真机矩阵 |
| L5 编排 | descriptor + CLI 选项 → 分阶段结果 | 私有签名细节、直接 hdc、应用名分支 | fake L2/L3/L4 全流程测试 |

`ohos-app` 对 `ohos-hap`/`ohos-device` 用**参数数组 spawn + 版本化 JSON 请求/响应**，不解析人类可读文本、不经过 shell、不形成反向调用。

---

## 3. 公开命令面

```text
ohos-app
  list [--json] / info <id> [--json]
  configure <id>                          # 仅声明了宿主集成的应用；不操作设备
  install <id> [--device SEL] [--variant NAME] [--signing-profile NAME]
           [--method auto|hdc|sideload] [--install-timeout DURATION] [--start] [--json]
  uninstall <id> [--device SEL] [--purge]
  start|stop|status <id> [--device SEL] [--json]
  logs <id> [--device SEL] / doctor [<id>] [--json] / cache list|prune

ohos-hap
  inspect --hap FILE [--json] / verify --hap FILE [--json]
  sign --input FILE --output FILE --profile NAME
  profile list|show|add|remove|refresh
  auth login|logout|status               # 永远由用户显式执行

ohos-device
  backends list [--json]
  list [--json]
  install --hap SIGNED_FILE [--device SEL] [--method auto|hdc|sideload]
          [--install-timeout DURATION] [--json]
  install-status --operation-id ID [--device SEL] [--json]
  uninstall --bundle-id ID [--device SEL] [--purge]
  start --bundle-id ID --module M --ability A [--device SEL]
  stop|status|permissions|logs --bundle-id ID [--device SEL] [--json]
```

约束：
- `ohos-app install` 默认不启动（`--start` 才 `aa start`），不自动执行 `configure`；缺配对配置时失败并给准确命令。
- `ohos-app` 不接受 `--hap`/keystore/密码；`--signing-profile` 只选 `ohos-hap` 中已有逻辑名。
- `ohos-hap` 永无设备参数；`ohos-device` 永不读 descriptor/签名材料/登录态。
- `ohos-device uninstall --bundle-id` 是 formula 删除后的逃生口。
- 多设备无唯一匹配即失败；`status` 只报设备侧，宿主服务健康由上游 CLI 报。

---

## 4. 身份与协议

### 4.1 四种身份严格独立

| 名称 | 职责 | 可推导性 |
|---|---|---|
| formula 短名 | Homebrew 本机交付包名（`codex-desktop`） | 按形态命名；不能推出 bundle 或 CLI |
| descriptor `id` | canonical formula 全名（`social4hyq/core/codex-desktop`） | CI 强制等于 canonical 名，不另设 `formula` 字段 |
| OHOS bundle ID | 设备应用身份/沙箱边界（`com.example.codex`） | 从 HAP 读取交叉验证，绝不从包名推导 |
| 应用命令名 | 上游宿主 CLI（`codex`） | 只由上游决定，不进 descriptor |

包名：`codex` = 上游 CLI 包，`codex-desktop` = 桌面 HAP/manifest/插件；`multica`/`harbor` 同样分离；无上游 CLI 的 Snow Shot 只交付 `snow-shot-desktop`。新形态用明确后缀（`<name>-mobile`），不用语义模糊的 `-app`。

### 4.2 manifest（`app.json` v1）

源码 `Resources/<name>-desktop/app.json.in` → bottle `pkgshare/ohos/app.json`，经 `opt/<formula>/...` 稳定路径访问；无中央注册表、不存 Cellar 路径。构建时写入真实 HAP 摘要、versionName/versionCode、插件摘要。

```json
{
  "schema_version": 1,
  "id": "social4hyq/core/multica-desktop",
  "requires": { "features": ["hap-zip64", "personalize-v1"] },
  "artifact": {
    "format": "hap", "path": "../../libexec/multica-desktop-unsigned.hap",
    "sha256": "<build-time-sha256>", "api": 12, "abis": ["arm64-v8a"],
    "bundle_id": "com.social4hyq.multica",
    "version_name": "<upstream-version>", "version_code": 123
  },
  "launch": { "module": "electron", "ability": "EntryAbility" },
  "variants": {
    "default": "acl",
    "definitions": {
      "basic": {},
      "acl": { "module_overlay": "module-acl.json", "sha256": "<overlay-sha256>" }
    }
  },
  "sources": { "lockfile": "sources.lock.json" },
  "assembly": { "protocol": 1, "plugin": "assembler/plugin.json", "config": {} },
  "personalization": { "protocol": 1, "plugin": "personalizer/plugin.json", "required_config": "default" }
}
```

- 封闭校验：未知字段/variant/能力/类型全 fail closed。
- `schema_version` 管文件结构；插件 `protocol` 管进程协议；`requires.features` 管能力；最低引擎版本只在安全修复必须拒绝旧引擎时引入。
- **禁止字段**：`runtime.command`、上游 CLI 命令清单、设备序列号、签名材料路径、密码/token、固定缓存目录、after-install shell 命令。
- ACL variant 不是版本 channel；package version 由 Homebrew 管、HAP versionName/versionCode 由 HAP 管，`status` 并列展示。

### 4.3 外部厂商制品（`sources.lock.json`）

通用 fetcher 统一处理下载、代理/CA、断点、SHA256 + 大小校验、内容寻址缓存；应用脚本不再各自 `curl`。URL 禁放长期 token；`--source desktop=/path` 离线覆盖仍强制同摘要。缓存用同文件系统临时文件 + 校验 + fsync + 原子发布。

### 4.4 插件协议

优先类型化通用 assembler（`electron-asar`/`vendor-deb-extract`/`config-inject`），表达不了才允许 app 自有插件。进程合同：

```text
plugin --protocol 1
  fd 3：JSON request / fd 4：JSON result / stdin 关闭
  stdout/stderr：仅日志（脱敏采集） / cwd：0700 独立目录
```

secret 只传引用（值不进 argv/env/request/日志）；环境白名单、超时、取消、输出大小限制由引擎执行；assembler 默认无网络/设备/宿主写、输出确定性；personalizer 只写用户私有目录；插件禁调用 `brew`/三个公开命令/`<app> install`，禁启动常驻进程；引擎拒绝嵌套部署。无 `after_install`，宿主配置走显式 `ohos-app configure`。

---

## 5. 签名与设备协议

### 5.1 签名材料（`ohos-hap` 独占）

SigningProfile：`name` / `kind`（external-material | vendor-debug）/ p7b / keystore / certificate / key_alias / `store_password_ref` / `key_password_ref`（keychain://、fd://、受保护文件引用）/ `vendor_adapter` / `vendor_state_root`。

- 非秘密配置放 `XDG_CONFIG_HOME/ohos-hap/`；私钥不复制到项目树/bottle/缓存；厂商 debug token 留在厂商 CLI/OS 凭据设施，ohos-hap 只持引用。
- 外部材料是首选稳定后端，可离线签名；厂商 debug 路径单独 `ohos-hap auth login` / `profile refresh`。
- DevEco ToolProvider/decoder/axios 差异封装在 vendor adapter，按 CLI/SDK/Node/adapter 协议锁兼容矩阵，未知布局 fail closed。
- **密码绝不进 argv**：优先受保护 fd/stdin、keychain、签名 agent；若工具只支持明文 argv，目标架构拒绝该后端，不以"临时兼容"恢复泄漏。签名后必须验证，失败不发布输出。
- **侧载不改变 kind**：`--method` 只传 `ohos-device`，绝不触发 ohos-hap 登录/刷新；只有官方出现现有 kind 无法表达的新凭据行为时才新增版本化 kind。

### 5.2 设备层（`ohos-device`，多后端）

```text
DeviceBackend
  capabilities()            -> {backend, available, targets, features, unavailable_reason}
  install(InstallRequest, emit_event) -> InstallResult
  query_install(operation_id) -> InstallState
  query_bundle(bundle_id)   -> BundleState
```

- `hdc backend`：上传、`bm install`、后置 `bm dump`。
- `sideload backend`：规范前只能力探测 + fail-closed `BACKEND_UNAVAILABLE`。
- `--method`：`hdc`/`sideload` 只用指定后端、不可用直接失败；`auto` 优先兼容侧载否则 hdc，**但只在启动安装动作前自动选择，系统安装器启动后绝不跨后端回退**。无人值守脚本用显式 `--method hdc`。

**安装包后置核验**：`bm dump` 核对 bundle、versionCode/versionName、证书公开指纹、权限；文本只作诊断。`aa start/force-stop` 管生命周期；默认 `bm uninstall -k` 保留数据，`--purge` 只清设备沙箱。锁粒度 device+bundle。设备安装**不是 Nix 式事务**，失败不自动卸载旧版。

### 5.3 侧载的用户确认协议（L0/L4/L5）

清场方案删的是持久化可执行愿望和后台补装，保留一次显式操作的生命周期。靠**结构化中间状态**兼容"用户确认"，而非恢复 pending：

```json
InstallRequest: { protocol_version, method, device, hap_path, hap_sha256,
  expected: { bundle_id, version_name, version_code, certificate_fingerprint, requested_permissions },
  wait, timeout_ms }
install_state:  { type, operation_id, backend, device,
  state: "awaiting_user_confirmation", observed_at }
install_result: { type, operation_id, backend, state: "installed",
  bundle: {...}, verification: {bundle_matched, version_matched, certificate_matched, permissions_matched}, error }
```

状态枚举固定：`awaiting_user_confirmation / installing / installed / rejected / cancelled / failed / unknown`。成功以实时后置状态为准，不凭进程退出 0；无法核验字段为 `null` 并标 `unsupported`，bundle ID + versionCode 是最低成功条件。

错误码：`BACKEND_UNAVAILABLE` / `INSTALL_REJECTED` / `INSTALL_CANCELLED` / `INSTALL_FAILED` / `WAIT_TIMEOUT` / `WAIT_INTERRUPTED` / `STATUS_QUERY_UNSUPPORTED` / `OPERATION_UNKNOWN` / `POST_INSTALL_VERIFY_FAILED`。**等待超时 ≠ 安装失败**：保留 operation_id + 最后状态，不取消 OS 操作；`--start` 只在 installed 且核验通过后执行。

无稳定操作 ID 时 `capabilities()` 声明不支持 `install-status`，**不自建 pending 模拟**。

**post_install 决策被侧载强化**（绝不回退）：brew 在非交互/清环境会话不适合持有系统安装器 UI；自动升级弹确认框会让包管理不可预期；写 pending 会重新引入愿望队列；brew 成功只表示文件交付，`ohos-app install` 成功才表示设备核验。

**权限清单**：从最终 signed HAP 实时提取 `requested_permissions`（name/grant_mode/acl/reason/used_scene），安装器启动前打印 basic/acl 差异、ACL 显著标出；不抓取/模拟系统 UI、不声称用户已看到或已授权。

---

## 6. 完整解耦清单（摘要）

| 当前耦合点 | 清场后拆法 |
|---|---|
| brew 交付 ↔ 设备部署 | 删全部 `post_install_steps`，唯一入口显式 `ohos-app install` |
| brew 临时 HOME ↔ 用户凭据 | 凭据组件在实际用户会话运行，按真实 HOME/XDG 解析，删 HOME 猜测 |
| 自动失败 ↔ pending 队列 | 同步命令直接非零，状态来自实时查询 |
| 应用 wrapper ↔ 上游 CLI | bin 透明 exec 上游，上游无 CLI 就不提供命令 |
| `*-app` 后缀 ↔ 安装器正则 | id 用 canonical 名，无后缀正则、无 wrapper sed |
| bundle ↔ formula ↔ 命令名 | 三类身份独立，bundle 从 HAP 验证 |
| 通用安装器 ↔ app shell 库 | manifest + 独立进程插件，fd JSON 协议，无 `source` |
| 安装 hook ↔ 高层入口 | 插件无部署句柄，禁回调，嵌套装机失败 |
| 签名 ↔ 装机 | ohos-hap 只收 unsigned 返 signed；ohos-device 只收 signed |
| 厂商登录 ↔ 设备操作 | 认证只在 ohos-hap 显式发生，设备层无登录概念 |
| 秘密 ↔ argv/日志/缓存 | 只传 secret ref、fd/keychain 输入、日志脱敏、0700 私有状态 |
| 设备 start/stop/status ↔ 宿主服务 | 前者只管 HAP，后者由上游 CLI/brew services 管 |
| 厂商下载 ↔ 应用脚本 | sources.lock + 通用 fetcher |
| 装配缓存 ↔ 代码版本 | 键含 shell HAP/厂商包/assembler/配置/ACL/ABI |
| 公共别名 ↔ 内部工具 | 只暴露三命令，decoder/assembler/bridge 全在 libexec |

---

## 6.2 Homebrew Cask 对标研究（权威，实测文档）

依据 `docs.brew.sh/Cask-Cookbook` 与 `How-to-Create-and-Maintain-a-Tap`（2026-11 抓取）。Cask 是 Homebrew 交付 GUI 应用的官方形态，是本设计最贴近的业界参照。结论：**Cask 的声明式交付、token 命名、uninstall/zap 分离强烈支持本方案；但 Cask 不签名、不部署到外部设备，这部分必须自研。**

### 6.2.1 直接印证本方案的 Cask 机制

| Cask 机制 | 本方案对应 | 判定 |
|---|---|---|
| 声明式 stanza：作者只声明"装什么"（version/sha256/url/app/binary），顺序无关，Homebrew 决定如何装 | `app.json` manifest 声明 artifact/variant/hook，引擎决定流程 | **一致**。强化了"公式只声明、引擎执行"的边界 |
| `app`/`binary`/`pkg`/`installer`/`command_wrapper` artifact stanza：声明要安装的制品，不是命令式脚本 | `app.json` 的 artifact + 类型化 assembler | **一致**，且 Cask 的 `command_wrapper`（无 CLI 时生成 shim、透明 exec）正对应"无上游 CLI 就不造命令" |
| `zap`（更彻底卸载，含用户文件/共享资源）与 `uninstall` **分离**，官方 cask 必须有 zap | `ohos-app uninstall [--purge]`：默认 `bm uninstall -k` 保留数据，`--purge` 才清沙箱 | **一致**（`--purge` 即 zap 语义，且明确不碰宿主配置）。Cask 把 zap 设为官方 cask 必需，佐证"purge 是独立、显式的破坏性操作" |
| `brew install --cask` 只把 app 移入 `/Applications`，**不自动启动** | `ohos-app install` 默认不启动，`--start` 才 `aa start` | **强一致**。Cask 从不因安装而启动 app，直接印证删除 post_install 自动启动/自动装机 |
| `auto_updates`：声明 app 自行更新，Homebrew 不干预 | Homebrew 管 package version，HAP 管 versionName/versionCode；不另造版本 channel | **一致**。Cask 也把"应用自更新"排除在包管理器之外 |
| Cask token 全局唯一、简化命名、与 formula 区分 | `<name>-desktop` 包名 + 上游 CLI 名分离，四种身份独立 | **一致**。Cask 明确要求 cask 名全局唯一且不能与 formula 冲突 |
| 结构化 `preflight_steps`/`postflight_steps`：只含字面参数的支持步骤、可序列化进 JSON API、不加载 cask Ruby、禁任意 Ruby | 版本化 manifest + fd JSON 插件协议、禁 `source`、禁回调 | **方向一致**。Cask 用"受限 DSL + JSON API"取代可执行 Ruby，正是本方案"插件外部进程 + 结构化合同"的同类思路 |
| `{{temp}}` 私有 0700 临时目录、install-time token、`{{...}}` 延迟展开 | secret 只传引用、0700 工作目录、不拼 shell 字符串 | **一致** |
| `installer script`/`pkg` **不在沙箱运行**（需广泛写权限/root），官方明确承认 | 压测 P0：进程隔离不是安全沙箱，v1 只执行受信 tap 插件、不以 root 跑 | **强印证**。Cask 官方承认 installer 不沙箱，正是本方案"不宣传强制隔离"的权威依据 |
| Caskroom 版本化 `$(brew --caskroom)/<token>/<version>/` + 不可变制品 | bottle 不可变 + opt 稳定路径 + 内容寻址缓存 | **一致** |

### 6.2.2 Cask 不覆盖、必须自研的部分

- **签名与凭据**：Cask 依赖 macOS Gatekeeper/公证，开发者签名由 Apple 生态处理；OHOS 需本地 debug profile + DevEco/AGC 登录 + `hap-sign-tool`，且密码不能进 argv（Cask 无对应概念）。
- **外部设备部署**：Cask 是**本机**安装（移入 `/Applications`）；本方案要把 signed HAP 部署到 hdc 设备或系统侧载安装器，含多设备选择、分片上传、`bm install`、后置核验、用户确认协议——全部无 Cask 对应物。
- **ACL 权限变体**：OHOS `basic`/`acl` 变体与权限清单是平台特有，Cask 无对应。
- **宿主 bridge/配对**：OHOS 沙箱读不到宿主、需 loopback 令牌桥；Cask 的 app 直接跑在本机，无此问题。

### 6.2.3 由 Cask 研究触发的方案微调

1. `uninstall --purge` 的文档表述统一为"**zap 语义**：只清设备沙箱数据，不碰宿主配置/缓存/token"，与 Cask zap 对齐，避免用户误以为 purge 会清一切。
2. 强调 `app.json` 是**声明式、顺序无关**的 manifest——实施 PR 1 schema 时禁止把 hook 写成有序命令列表（Cask 只有 `*_steps` 是有序的，本方案的 assembler 是类型化输入输出合同，不是 DAG）。
3. `ohos-app configure` 的定位对标 Cask `postflight_steps`：是受限、显式、可序列化的补充步骤，不是任意 shell；宿主配置写入走应用私有配置根。

---

## 6.5 第六轮压测修正（Codex 6.2-sol，权威补充）

本节来自对定稿的第六轮对抗压测（`/data/storage/el2/base/cache/stress-final.md`）。它**不改变清场目标**，但修正了实施顺序和几处会导致第一周翻车的细节。与本节冲突时以本节为准。

**核心修正**：① L2 放 `ohos-app` 私有 libexec，不建独立 `ohos-fetch` formula；② 三个公开命令各出一个 formula（定稿已如此，确认不再拆侧载）；③ 原 PR 顺序需重排——先证明"不发布也能消费上一步 bottle"和"真实加密材料不经 argv 就能签出真机可装 HAP"，再铺 17 个迁移；④ 必须补做私有发布演练，现有 CI 流水线不能直接跑 `next`。

**L2 归属（定稿第 303 行未定点，此处定死）**：通用 fetcher + 内置类型化 assembler 放 `Resources/ohos-app/libexec/l2/` → 安装后的 `ohos-app/libexec/l2/`，作为 `ohos-app` 私有进程入口。L2 不解析 app ID、不扫描 opt、不决定何时签名/安装、不管理用户配置、不加载自己的插件目录；类型是有限的输入输出合同，不是可写命令/表达式/任意路径/配方 DAG。遇到类型表达不了的应用，由该 desktop bottle 带专属插件，走同一外部进程合同。**不建第四个 `ohos-fetch` formula，也不让 17 个 desktop 各带一套 L2。** 依赖按实际执行者算：Node/归档工具归 `ohos-app`，专属插件额外运行时由提供插件的 desktop 声明。

**合同归属（PR 1 路径修正）**：L0 合同只有**一份权威源**（repo 根 `contracts/ohos-app/v1/`），各 formula 按需装同源投影快照，不跨 keg 读共享 JSON、不手工双写。`descriptor`/`l2`/`plugins`/`sign`/`device` 五组 schema 分别投影到对应 formula 的 `Resources/<formula>/schemas/v1/`，字面列入 `RESOURCE_FILES`；CI 校验快照与声明支持的合同版本一致，兼容测试须实际装旧组件替换其一。

**首周四个 P0 阻塞（不过就不铺 17 个迁移）**：
1. **签名无明文 argv**：本机 `hap-sign-tool sign-app -help` 有 `-pwdInputMode 1`（交互输入），帮助不等于支持 pipe/fd。先用加密测试材料验证无回显、子进程 argv/日志无泄漏、超时、错误密码、无 TTY、真机接受；不能满足受保护合同则该后端 fail closed。
2. **manifest 解析根**：`app.json` 的 `../../libexec` 合法，但必须固定"本次解析出的同一 canonical keg"为根，拒绝逃逸 symlink；只扫 opt 不能保证跨 tap 同名消歧，报冲突而非建可写注册表。
3. **进程隔离≠安全沙箱**：白名单 env/fd/0700/拒绝嵌套只控制继承能力，不能阻止同 UID 插件读 HOME/联网。v1 只执行已安装且校验过的受信 tap 插件，不以 root 跑插件；无真机隔离证据前不宣传强制隔离。
4. **设备判成功**：同版重装时旧 HAP 的 `bm dump` 本就符合 bundle/versionCode，必须另有"本次操作成功"证据；无法关联时只报"已存在匹配版本/本次结果未知"，不退出 0、不 `--start`。

**状态边界**：允许"用户给系统什么输入"和"系统现在怎样"，不允许"系统以后替用户做什么"。`configure`/`personalize` 幂等、不写 `needs_config`/`configured_version` 队列；配对 token 只能经受限文件/句柄在私有目录读取，不能声称已部署 HAP 里的配对值对设备持有者保密；权限清单是本次派生观察，不维护"已授权/待补授权"表。

**会话边界（按子命令分，不在入口统一拦截）**：只读命令（brew 交付、`ohos-app list/info`、`ohos-hap inspect/verify`、`ohos-device backends/list/status/permissions`）允许 CI/root，缺设备权限报结构化不可用而非缺账户；认证类（`auth login`、`profile refresh`）限调用者本人、基于真实 UID 与会话能力，无 GUI/锁屏明确失败不无限等待；签名/安装用专用低权限 UID 与明确材料，缺凭据给稳定错误不自动 login/refresh。测试覆盖双 UID、伪 HOME、锁屏、无 session、凭据过期、同账户并发 refresh。

---

## 7. 按组件/PR 拆分实施（一 PR 一组件/formula，独立 worktree）

遵守 CLAUDE.md 硬约束：一 PR 一 formula、每个改动走独立 worktree（如 `../Software/<project>/tap-work`）、改 formula 必查 revision + `style`/`audit`/`readall` 全绿、改 patch 必从原文件重生成 hunk、**禁手改 `@@`**、提交署 `social4hyq <social4hyq@163.com>`、上游验证先提 `social4hyq/homebrew-core` PR（禁直接向 Harmonybrew AtomGit 提 MR）。所有中间 PR 进**不自动发布的 `next` 集成分支**，全部完成再一次性切换。

> 本机 `--build-from-source`/`--build-bottle` 被 CLI 硬禁用，源码构建一律走 CI（`pr-validate` 顺带出 bottle）；本机只跑 `brew style`/`audit`/`readall`。构建日志落对应工程 `logs/`，TMPDIR 用 `/data/storage/el2/base/cache`。grep 用 `grep -E "...|..."`（本机 `grep "a\|b"` 对文本和二进制都会假阴性静默返回 0）；bash 专属语法 `bash -c` 包一层；脚本变量禁用 `status`（zsh 只读）。

### PR 0a — 文档与迁移台账

本文件（`docs/ohos-app-refactor-plan.md`，即权威源）同步到 tap；Workspace 保留入口并写明同步关系，不引用 EL2 临时报告作为实施依赖。建 17 行迁移台账（每行：签名/权限/宿主分类、PR 所有者、验收勾项）、CLI 归属清单、旧名/alias/服务/私有镜像清单。
验证：两仓文档版本一致；17 行台账齐全；现有 17 个旧 formula 不改。

### PR 0b — 私有构建、静态门禁与发布演练（**首发前必须完成**）

现有 CI `pr-validate.yml` 只对 main 的 PR 触发且 `upload: true`，`publish-on-merge.yml`/`sync-to-atomgit.yml` 盯 main，**不能直接跑 `next`**。本 PR：纯基础设施落分支门禁；`next` 的构建与发布权限分离，CI 只出私有可追溯 artifact；安装依赖环节接到私有冻结 tap 快照和 bottle 索引/镜像；先用两个有依赖的测试 formula 演练。
验证：PR 合并候选 SHA 出 bottle；洁净 runner 从同一快照 pour 上游 bottle 并构建下游（实测非 source fallback）；零公开 tag/release/回写 main；模拟切换失败时旧索引仍可用。

### PR 1 — L0 合同（现在可做，先于 PR 2a/2b/3/4）

repo 根 `contracts/ohos-app/v1/` 唯一权威源：`descriptor`/`l2`/`plugins`/`sign`/`device` 五组 schema + CLI 签名/设备消息 framing + 错误码 + 权限 + 插件/路径规则。各 formula 出现后按需装同源投影快照到 `Resources/<formula>/schemas/v1/`，字面列入 `RESOURCE_FILES`。
验证：golden 正反例、断流/重复终态/协议版本不匹配、路径逃逸、缺能力均有预期结果；快照与声明支持的合同版本一致；兼容测试实际装旧组件替换其一。

### PR 2a — 签名硬阻塞验证（可在 PR 0b/1 期间试验）

先用固定 SDK + 本机真实加密测试材料验证无明文 argv 签名（`-pwdInputMode 1` 等受保护输入），再迁 DevEco 离线签名。**不过此关不铺 17 个迁移**。验证：正确/错误密码、有无终端、有界失败、无明文泄漏、输出通过验证、测试材料所签 HAP 在试点设备可被接受。

### PR 2b — `ohos-hap` 签名组件

```
Formula/o/ohos-hap.rb
Resources/ohos-hap/{sign-hap.cjs,inspect.cjs,prepare-profile.cjs,deveco-decoder.cjs,...}
Resources/ohos-hap/lib/vendor-adapter/...        # 按 DevEco/SDK/Node 锁兼容矩阵
Resources/ohos-hap/test-*.cjs
```
自包含 DevEco runtime（原 app-installer libexec 迁入），禁 `devecocli` 公共入口；不把旧 SDK 树 hdc wrapper 原样搬入并实际调用。验证：fake signer、真实测试证书、密码不进 argv、decoder 未知布局 fail closed、inspect 权限 golden。

### PR 3 — `ohos-device` 多后端设备组件（含侧载合同）

```
Formula/o/ohos-device.rb
Resources/ohos-device/ohos-device.sh              # backends list / install --method / install-status
Resources/ohos-device/lib/install-service.cjs     # 事件流、device+bundle 锁、等待、取消、后置核验
Resources/ohos-device/lib/backends/hdc.cjs
Resources/ohos-device/lib/backends/sideload.cjs   # 规范前只能力探测 + fail-closed
Resources/ohos-device/test/{fake-hdc,fake-sideload,test-device}.cjs
```
可独立于 `ohos-hap`/DevEco 单测与真机查询；standalone install 自行从制品推导/校验身份，不信任 CLI 自报 bundle/摘要，但不反向调用 L3、不把"看到签名块"说成密码学验证。双 fake 覆盖：hdc 不回归、sideload 事件顺序/操作 ID、接受/拒绝/取消/失败/句柄丢失、超时不伪报、核验不符、auto 选择、拒绝/取消/超时后绝不调 hdc、无 pending/后台进程。注意"显式 sideload 不可用就不签名"的断言移到 PR 4（L4 观察不到 L3 是否签名）。

### PR 4 — `ohos-app` 编排薄片（先最薄链路，后插件能力）

```
Formula/o/ohos-app.rb
Resources/ohos-app/ohos-app.sh
Resources/ohos-app/lib/{install-orchestrator.cjs,permission-summary.cjs}
Resources/ohos-app/libexec/l2/                       # L2 私有归宿：fetcher + 类型化 assembler
Resources/ohos-app/test-app.cjs
```
第一版只做 GenOffice 所需最终接口（list/info/install/status/start/uninstall + preflight + 权限渲染），暂不做完整下载/插件/configure。设出包门禁：实现只含通用执行步骤和渲染，权限数据以 L3 从最终 signed HAP 提取为准，L5 只显示并传合同；应用名分支/登录/设备调用/宿主服务启动/自动重试一旦进入 L5 即拒绝合入。验证：fake 全链路证明不可用后端在签名前失败、确认未结束不返回成功、可区分安装成功而启动失败。

### PR 5 — L2 及首个厂商样本

L2 代码在 `ohos-app` 单 PR 合入（归属见 §6.5）；第一个厂商 desktop 紧接独立 PR。以一个真实厂商包 + HAP fixture 定第一个类型，不为没有样本的应用预造 assembler 类型。验证：新 `ohos-app` 测试 bottle 已可用、离线同摘要 `--source` 跑完整链路、错摘要/ZIP64/失效键/中断恢复。

### PR 6a — GenOffice 先行试点（不是三个试点一起等）

`Formula/g/genoffice-desktop.rb`（单逻辑 formula 改名迁移）+ `Resources/genoffice-desktop/app.json.in`；去掉仅为旧共享脚本而造的时间戳。**Harbor 不作为最先试点**：旧 `harbor-app.rb` 还交付 `harbor` CLI 且 HAP 带 ACL 断言，若须新建 CLI 先出 CLI 测试 bottle。验证：真机从私有 bottle 断网 pour 不触设备，再显式签名/安装/启动/卸载；无插件、无 pending。

### PR 7a/6b/7b/8b — 补齐其余 16 个应用（逐 app 独立 PR，一 PR 一 formula）

- 厂商装配类（PR 7a/7b）：Codex、Claude、Bruno、Obsidian、Antigravity、Antigravity IDE — 加 `sources.lock.json`，下载走通用 fetcher、装配走类型化 assembler、宿主配置走显式 `configure`。验证 sha256 强校验、离线 `--source` 同摘要、Codex 配置修改在 configure、Antigravity `xdg-open` 仅私有目录。
- 个性化/宿主类（PR 8b）：Multica、Herdr（+ Brewo 注册）— `configure` 显式生成/复用配对配置，`personalize` 注入 HAP，安装不启动 bridge；上游 CLI/服务如需改动各自一个前置 formula PR。验证全新环境首次启动、token 跨升级不变、未显式启动宿主服务时不偷启动。
- 其余（PR 6b）：**DeepSeek Harness、Magpie、OpenCode、Orca、ZCode、Harbor、Snow Shot** — 原计划只点到 12 个，漏列这 7 个（其中 5 个此前完全没提）。Orca/ZCode 现有安装测试传 `--no-serve`，不能用删 wrapper 等同于已迁宿主服务。CLI 透明 exec **按改变 CLI 的那个 formula 验收**：比对 argv（含未知参数）、退出码、stdout/stderr/JSON、信号与无 HAP 副作用，帮助快照只是基线不是验收。
- 每次迁移后整体可装、受影响 app 冒烟、依赖先合并且有 bottle。**同次迁移删除指向该旧包的 rename/alias 项**（`formula_renames.json` 现有 `opencode-desktop → opencode-app` 等五条以最终 desktop 名作旧键），PR 门禁用全限定名实测解析并 pour，不只看文件存在。

### PR 9a — 删除旧轨

确认无 formula 依赖后删 `Formula/a/app-installer.rb`、`Resources/app-installer/`、`Resources/_shared/hap-app/install-lib.sh`、旧公开命令（六名 + 两套 sign 别名 + 公共 devecocli）及旧门禁/配置，按 formula/基础设施拆。**不建旧命令 shim、不读不迁旧 pending、不删用户旧配置/token**。注意：删 tap 文件**不清除用户已装 keg 的 bin/launch 配置**，发版说明必须给出显式清旧、消链接冲突、装新工具、显式部署的顺序。

### PR 9b — 发布切换（独立受保护动作，不是普通 formula PR）

"一次性切换"是**公开索引的一个开关**，不是多仓库/17 台用户机器的事务。发版前冻结受影响的 bump/publish/sync，核对 main 漂移；把经测试的同一批 bottle 提升为生产可下载位置，校验大小/哈希和 clean pour，生成完整 bottle blocks；全部就绪后推进公开索引、恢复镜像与自动化。按现有 release 脚本做不到严格跨平台原子公开，若要求资产 URL 不可短暂可见须在 PR 0b 验证私有预置方案。旧资产/旧索引暂不清理；公开后以新体系修复或增 revision 重发，不自动重装/降级设备应用。

### PR E/F — 侧载 adapter 与真机矩阵（**等官方规范**，脚本骨架可先写）

官方规范公布后实现 `sideload.cjs` 的能力探测/入口/操作 ID 映射/错误码映射（必要时 `sideload-<official-api>.cjs`）。真机矩阵见 §8 第 10 条 + §5.3。规范前真实侧载保持 `BACKEND_UNAVAILABLE`，不得用私有 API/无障碍自动点击绕过用户，不得把 auto 侧载标为生产可用。

---

## 8. 验收合同

1. **交付纯净**：全部 desktop formula 的 install/upgrade/pour 不访问设备、不登录、不弹安装器、不启服务、不改宿主配置、不写 pending。
2. **命令清晰**：tap 自有公开命令只有三个；无 `ohos-dev`、`xx-app install` 或旧名 shim。
3. **上游透明**：`claude install/stop`、`opencode uninstall/service`、`magpie status/uninstall`、`harbor start/stop` 保持上游语义，不触发 HAP 操作。
4. **无回环**：运行追踪只有 `ohos-app → artifact/sign/device` 单向调用，插件不能回调高层入口。
5. **显式部署**：只有 `ohos-app install`/底层显式命令才签名部署，默认不启动，失败非零，无后台补装。
6. **签名独立**：无设备可 inspect/sign/verify；未登录不影响不需新签名的查询/卸载；秘密不进 argv/日志/descriptor/共享缓存。
7. **设备可信**：安装成功以 `bm dump` 后置状态为准；多设备不歧义；默认保留数据，purge 不碰宿主数据。
8. **运行时不混层**：`ohos-app start/stop/status` 只操作设备 HAP；daemon/bridge 只能由上游 CLI/brew services 显式控制。
9. **缓存正确**：assembler/厂商包/shell HAP/variant/ABI 任一变化使共享缓存失效；配对配置和签名材料永不进共享缓存。
10. **侧载协议**（fake 可先测，真机等规范）：basic/acl 首次安装接受并后置核验；用户拒绝=`INSTALL_REJECTED`、取消=`INSTALL_CANCELLED`、等待超时=`WAIT_TIMEOUT`（不伪报失败/不取消 OS 操作）；拒绝/取消/超时后绝不调 hdc；无 pending/后台补装；禁用 hdc 后全链路不依赖 hdc；`auto` 两可用性且侧载动作开始后不回退；无图形会话有界等待；brew 零副作用；重开会话无自动补装。
11. **版本可解释**：本机 bottle 版本、HAP versionName/versionCode、设备实际版本分别可见；升级失败不伪称事务回滚、不自动清数据。
12. **维护局部化 + 真实验收**：新增普通 app 不改引擎；通用修复不要求全部 app 重建；上游 CLI 升级不需同步手写命令表；真实加密材料签名和真机安装必须通过，不能以 fake hdc/布局识别/编译成功代替。
13. **本次操作可证**：同版重装/旧 HAP 已匹配时，不凭 `bm dump` 版本相同就退出 0；无本次成功证据时只报"已存在匹配版本/本次结果未知"，不 `--start`。签名密码无明文 argv，manifest 路径逃逸被拒，插件不以 root 运行。
14. **发布隔离**：`next` 候选 SHA 出 bottle，洁净 runner 从私有冻结快照 pour 并构建下游（非 source fallback）；零公开 tag/release/回写 main；切换前冻结 bump/publish/sync，按全限定名实测 rename/pour；发版说明含显式清旧顺序，不清除用户已装 keg 的 bin/launch 配置不视为已迁移。

---

## 9. 验收脚本骨架（伪代码，按组件分文件）

```js
// Resources/ohos-device/test-device.cjs —— 双后端同合同
test('hdc backend: upload/install/verify 不调用 sideload', () => {
  const r = runDevice(['install','--hap',fixture,'--method','hdc'], {fakeHdc, fakeSideload});
  assert.equal(r.state, 'installed'); assert.equal(fakeSideload.calls, 0);
});
test('sideload: 等待确认→安装中→已安装，事件顺序与 operation_id 正确', () => {
  const r = runDevice(['install','--hap',fixture,'--method','sideload'], {fakeSideload});
  assert.deepEqual(r.states, ['awaiting_user_confirmation','installing','installed']);
  assert.ok(r.operation_id); assert.equal(r.verification.bundle_matched, true);
});
test('用户拒绝/取消/超时：非零、错误码稳定、绝不切 hdc、无 pending', () => {
  for (const [mode, code] of [['reject','INSTALL_REJECTED'],['cancel','INSTALL_CANCELLED'],['timeout','WAIT_TIMEOUT']]) {
    // mode 是 fake 的行为开关，须显式构造对应 fake 实例，不能用未定义的 _mode
    const r = runDevice(['install','--method','sideload'], {fakeSideload: makeFakeSideload(mode)});
    assert.notEqual(r.status, 0); assert.equal(r.error.code, code);
    assert.equal(fakeHdc.calls, 0); assert.equal(pendingFileExists(), false);
  }
});
test('后核验不符：POST_INSTALL_VERIFY_FAILED，不卸载旧版不清数据', () => { /* ... */ });
test('auto：侧载不可用选 hdc，可用选侧载；动作开始后不跨后端回退', () => { /* ... */ });
```

```js
// Resources/ohos-app/test-app.cjs —— 编排层合同
test('fake L4 收到 signed 而非 unsigned HAP；fake L3 无设备参数', () => { /* ... */ });
test('确认未结束无成功输出；超时/取消非零且无 pending', () => { /* ... */ });
test('ohos-app 源码无 hdc/bm/installer intent 直接调用', () => {
  const src = readFileSync('Resources/ohos-app/ohos-app.sh','utf8');
  assert.doesNotMatch(src, /\bhdc\b|\bbm\b|installer.intent/);
});
```

```sh
# CI 静态断言（.github/scripts/check-ohos-app-architecture.sh，bash -c 执行）
# 注意：按迁移状态检查，不要全树一刀切。旧检查要求依赖 app-installer 就有 post_install_steps；
# 新规则是「已迁移的 desktop formula 不得有 post_install_steps」，不是所有 formula 都不能有。
# 示例（迁移白名单由迁移台账驱动，这里的 APP_LIST 仅为占位）：
for f in $MIGRATED_DESKTOP_FORMULAE; do
  grep -qE 'post_install_steps' "Formula/${f:0:1}/$f.rb" && { echo "$f 仍有 post_install_steps"; exit 1; }
done
grep -rEn 'runtime\.command' Resources Formula 2>/dev/null && exit 1 || true
# 禁止直接执行 hdc/bm 是禁止「组件执行点」，不是禁止 --method hdc 字样：
# 用 fake 记录调用路径做运行时断言，不靠 grep 入口脚本。
# 本机必须用 grep -E，禁用 grep "a\|b"（后者对文本/二进制假阴性静默返回 0）。
# 每个检查（含资源清单、旧名解析、help/CI 规则）都要有负例，避免「零问题」其实没跑到目标。
```

---

## 10. 现在可做 vs 需等规范

**现在可做**（不依赖官方侧载细节）：三命令边界与 L4 后端封装；`--method`/能力集/中间状态/NDJSON/操作查询/稳定错误码；hdc + fake sideload 同合同测试；前台有界等待并区分超时与失败；禁止动作开始后跨后端回退；从 signed HAP 生成权限清单与 basic/acl 差异；删 post_install/pending/后台补装；未知后端 fail-closed；保留 SigningProfile 扩展点但不造侧载 kind；预写真机矩阵（fake 不构成部署证明）。PR 1 起把 `--source NAME=PATH`（离线同摘要覆盖）列入 CLI 验收，原计划漏列。

**需等官宣**：入口（system installer/intent/URI/API/bm 新参数及文件传递）、签名要求（provision/证书类型/设备绑定/debug-release/ACL 资格/是否系统代签）、交互（确认字段/拒绝取消区别/无图形会话行为）、操作模型（操作 ID/轮询/句柄有效期）、后置查询能力、能力探测依据、升级语义（同版本重装/降级/数据保留）、目标范围（是否仅本机）、是否新增 SigningProfile kind。

---

## 11. 参考：六轮 + 侧载研究原始报告

- 第一轮（descriptor 消回环）：`/data/storage/el2/base/cache/kimi-final.md`
- 第二轮（激进重构 / ohos-app）：`.../kimi-adversarial-final.md`
- 第三轮（可行性反弹 / opt-in 与不改名）：`.../kimi-adversarial2-final.md`
- 第四轮（清场最终设计）：`.../kimi-final-design.md`
- 侧载适配性研究：`.../sideload-final.md`
- 第六轮（实施压测，Codex 6.2-sol）：`.../stress-final.md`

本文件是上述结论的收敛落地版；细节冲突时以本文件为准，原始报告仅作推理溯源。
