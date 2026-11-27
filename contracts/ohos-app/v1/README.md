# ohos-app L0 合同 v1

本目录是 `ohos-app` / `ohos-hap` / `ohos-device` 三命令之间，以及它们与 desktop formula 之间**唯一权威的合同源**。各 formula 安装时把所需 schema 投影到自己的 `Resources/<formula>/schemas/v1/`，投影由脚本生成，不手工双写。

## 合同分层

| 组 | 文件 | 消费者 | 装包归属 |
|---|---|---|---|
| descriptor | `descriptor/app.schema.json`、`sources-lock.schema.json`、`plugin-descriptor.schema.json` | `ohos-app` 校验 app.json；desktop CI 校验但不重复分发 | `Resources/ohos-app/schemas/v1/` |
| l2 | `l2/fetch-request.schema.json`、`fetch-result.schema.json`、`assembly-request.schema.json`、`assembly-result.schema.json`、`typed-assembly-config.schema.json` | 通用 fetcher / 类型化 assembler 的进程输入输出 | `Resources/ohos-app/schemas/v1/` |
| plugins | `plugins/assembler.schema.json`、`personalizer.schema.json`、`host-integration.schema.json` | 应用专属插件的协议描述（互斥分支：内置类型 XOR 可执行插件） | `Resources/ohos-app/schemas/v1/` |
| sign | `sign/request.schema.json`、`result.schema.json`、`inspect-result.schema.json` | `ohos-hap` 签名进程协议；`ohos-app` 只装调用契约 | `ohos-hap` 装服务端全集；`ohos-app` 装调用契约 |
| device | `device/backend-capabilities.schema.json`、`install-request.schema.json`、`install-state.schema.json`、`install-result.schema.json`、`install-event.schema.json`、`device-contract.schema.json` | `ohos-device` 服务端 + `ohos-app` 客户端同源投影 | `ohos-device` 装服务端；`ohos-app` 装客户端 |
| 错误码 | `errors.json` | 三命令共用的稳定错误码 | 全部 |
| framing | `framing.md` | NDJSON 事件流、请求/响应 framing、版本协商 | 全部 |

## 版本与兼容规则

- `schema_version` 只描述文件结构；插件 `protocol` 描述进程协议；能力用 `requires.features`；**最低引擎版本只在安全修复必须拒绝旧引擎时**引入。
- 同一主版本内：不得新增会被旧端拒绝的 wire 字段/枚举；新增字段必须可选、带默认值，旧端忽略。
- 不兼容变更：提升主版本（目录 `v2/`），显式更新消费者，禁止静默回退旧命令。
- `requires.features` 中未知能力 → fail closed（`ERROR_UNSUPPORTED_FEATURE`）。
- 路径：一切相对路径只相对 manifest 所在目录解析，拒绝逃逸与符号链接逃逸；安装时固定"本次解析出的同一 canonical keg"为根。

## 禁止出现在任何 descriptor / 合同中的字段

`runtime.command`、上游 CLI 命令清单、设备序列号、签名材料路径、密码/token 值、固定缓存目录、after-install shell 命令、secret 明文（只允许 `secret_ref`）。

## 校验

```sh
python3 scripts/check-ohos-app-contracts.py --root contracts/ohos-app/v1 --fixtures contracts/ohos-app/v1/fixtures
```

校验器只依赖 Python 标准库（tap 运行环境的约束），golden 正反例覆盖：缺字段、未知字段、错误类型、路径逃逸、协议版本不匹配、secret 明文、未知能力。
