# L0 framing v1 — 进程间消息与事件流

所有跨命令调用（ohos-app → ohos-hap / ohos-device）遵守本约定。目标：不解析人类可读文本、不经过 shell、可机读、版本可协商。

## 调用方式
- 参数数组 spawn（argv），**禁止** shell 字符串拼接。
- 请求与结果用 JSON 文件（路径作为 argv 传入）或 fd 传递；秘密只传 `*_ref`，值不进 argv/env/JSON/日志。
- 环境变量白名单由引擎执行；cwd 0700；超时与输出上限由引擎执行。

## 设备事件流（NDJSON）
- `ohos-device install` 在 stdout 输出 NDJSON，每行符合 `install-event.schema.json`。
- 一次操作**恰好一个** `install_result` 终结记录；`install_state` 是中间态，可多条。
- 终结记录必须包含 `state` 与 `error`：`state=installed` 才算成功；`rejected/cancelled/failed/unknown` 均非零。
- `WAIT_TIMEOUT` / `WAIT_INTERRUPTED` 是**本地等待结束**，不是 OS 终态——结果中保留 `operation_id` 与最后已知状态，不取消 OS 操作。
- 畸形/截断 NDJSON、退出码与终结记录不一致 → 合同违规（`ERR_INVALID_REQUEST`），机器消费者不得据部分输出判成功。

## 查询
- `ohos-device install-status --operation-id ID`：**取得状态即退出 0**（即使 state=failed）；调用者看 `state`/`error.code`。
- 查不到 → `ERR_OPERATION_UNKNOWN`（非零）；后端不支持查询 → `ERR_STATUS_QUERY_UNSUPPORTED`（非零）。
- 没有官方稳定句柄时，`capabilities()` 声明不支持 `install-status`，**不得自建 pending 数据库或伪造可查询 ID**。

## 版本协商
- 每个请求/结果带 `protocol_version`；不匹配 → `ERR_UNSUPPORTED_PROTOCOL`，fail closed，不回退旧命令。
- 同一主版本新增字段必须可选、带默认值；旧端忽略。破坏性变更提升主版本（v2/）。

## 幂等与成功判定
- `install` 不凭"装后有同版本"退出 0（同版重装时旧 HAP 的 `bm dump` 本就匹配）；必须有本次操作成功证据 + 实时后置核验，无法关联时只报"已存在匹配版本/本次结果未知"，不 `--start`。
- 后置核验字段：`bundle_matched` / `version_matched` / `certificate_matched` / `permissions_matched`；无法核验填 `null` 并在 `unsupported` 列出，不伪造 `true`。
