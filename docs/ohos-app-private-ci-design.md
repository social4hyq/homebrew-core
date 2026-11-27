# PR 0b：私有构建与发布演练设计（可执行方案）

本文是 `docs/ohos-app-refactor-plan.md` 中 PR 0b 的实施设计。目标：让 `next` 集成分支上的新架构组件（ohos-app/ohos-hap/ohos-device 与 17 个 desktop formula）能在**不公开发布、不回写 main**的前提下，完成构建、bottle、下游依赖 pour 验证和切换演练。

## 1. 问题（来自第六轮压测）

现有流水线的三个事实（已核对 `.github/workflows/`）：
1. `pr-validate.yml:32` / `publish-on-merge.yml:29` 的 `on.pull_request/push.branches` 均为 `[main]`；`pr-validate` 的 build job（`:190`）传 `upload: true`，即 bottle 在审查期就发布到 atomgit release 并回写 PR 分支。
2. `bottle-build.yml:35-62` 支持 `upload=false`：`bottle.sh` 生成一次性 tag `<formula>-v<ver>-ci<RUN_NUMBER>` 与 **fake root-url**（`bottle.sh:36-37`，指向 github release 而非 atomgit），并把 bottle 作为 workflow artifact 上传（`:160-166`，retention 14 天），不改仓库。
3. `verify-poured.sh` 依赖 formula 的 bottle block 指向**已发布**的 atomgit root-url，删 keg 后 `brew install` 重新 pour。

结论：**不能直接把 `next` 塞进现有工作流**。只改分支触发会把"未合 main"错当成"未发布"；把 `upload` 关掉则下游拿不到可安装依赖。必须先建立私有链路。

## 2. 目标链路

```
next 分支 PR
  → 新工作流 next-private-ci.yml（本 PR 新增）
      → 对每个新组件/迁移 app 调 bottle-build(upload=false) → 私有 artifact
      → 把 artifact 汇入"私有 bottle 索引"（同一 run 内可下载）
      → 下游用私有索引解析依赖并 pour（验证非 source fallback）
      → 全程零公开 tag/release、零回写 main
  → 演练：模拟切换失败时旧索引仍可用
```

## 3. 需要新增/修改的文件

### 3.1 新增 `.github/workflows/next-private-ci.yml`（workflow_call + workflow_dispatch）

- 触发：`workflow_dispatch`（手动演练）+ 可被其他工作流 `workflow_call`。
- 输入：`branch`（默认 `next`）、`formulae`（逗号分隔的待构建列表）、`private_root_url`（私有 bottle 基址）、`exercise_switch`（是否跑切换演练）。
- `on.workflow_dispatch` 与 `workflow_call` 共用同一 jobs，参数走 env，不插值进 shell（沿用 bottle-build.yml:105 的白名单做法）。
- 分支守卫：`[[ "$BRANCH" != main ]] || exit 1`，防止误对 main 跑私有链路。
- 权限分离：构建 job 只 `contents: read` + artifact 上传；发布/切换 job 单独，且默认不启用（演练才是目的）。

### 3.2 新增 `.github/scripts/private-bottle-index.sh`

职责：把同一 workflow run 的多个 bottle artifact 汇成一个可供 brew 消费的私有索引。
- 输入：`bottle-out/` 集合（每个 artifact 含 `*.tar.gz` + `*.json`）。
- 产出：`private-index/<formula>.json`（改 bottle block 的 root_url 为 `private_root_url`）+ 一个目录清单。
- 关键：不发明假的可查询 ID，不伪装公开 release；index 只在本 run 内有效。

### 3.3 新增 `.github/scripts/private-pour-verify.sh`

职责：在下游构建前，让 brew 从私有索引 pour 上游 bottle 而非 source。
- 已核对：现有脚本**没有** bottle root-url 的环境变量覆盖（`lib.sh` 仅 `BREW_ENV`/`CONTAINER`/`TAP`；`publish.sh:370-397` 的 GitHub 镜像只是 copy，不是 root_url 切换）。所以不能假设有现成开关。
- 做法（两选一，实施时先用 A 验证）：
  - **A（首选）**：在容器内的**临时 tap 副本**上，把上游 formula bottle block 的 `root_url` 改为本地 `file://` 路径或 `private_root_url`，再用 `brew install`；不改仓库、不回写。
  - **B**：`brew install --force-bottle` 配合自定义 bottle 镜像目录（需先实测该 fork 的 brew 是否支持，不支持就放弃 B 用 A）。
- 用 `verify-poured.sh` 同款逻辑（删 keg → `brew install` → 断言 `poured_from_bottle=true`）验证。
- 必须实测：下游构建日志里上游依赖是 pour 而非 `brew install --build-from-source`；若出现 source fallback 则失败。

### 3.4 修改 `.github/workflows/bottle-build.yml`（最小改动）

- 增加可选输入 `private_index`（默认空）。非空时，`bottle.sh` 生成的 root-url 改用私有基址（通过 env 传入，不改公开逻辑）。
- 保持 `upload=false` 行为不变；仅当 `private_index` 非空且 `upload=false` 时启用私有路径。
- 不改 `upload=true`（公开发布）路径，避免影响现有管线。

### 3.5 修改 `.github/scripts/bottle.sh`（最小改动）

- 在非公开分支（`PRIVATE_ROOT_URL` 非空）时，`ROOT="${PRIVATE_ROOT_URL}"`，tag 仍用 `-ci<RUN_NUMBER>`。
- 保持公开路径逐字不变。

### 3.6 新增 `.github/workflows/next-switch-rehearsal.yml`（切换演练）

- `workflow_dispatch`，输入 `mode=pre|post`（切换前/后）。
- pre：验证旧索引可用、旧 bottle 可 pour、无公开 tag 被创建。
- post：用私有索引模拟公开索引切换——断言 bottle blocks 完整、clean pour 成功、无 source fallback；失败只撤候选，不动公开 refs。
- 演练不发布任何资产。

## 4. 验证（可验证标志）

1. PR 合并候选 SHA 出 bottle：artifact 名含 candidate SHA。
2. 洁净 runner 从同一快照 pour 上游 bottle 并构建下游，`poured_from_bottle=true`，日志无 source fallback。
3. 零公开 tag/release、零回写 main：`next-private-ci.yml` 全程无 `upload=true`、无 `publish-on-merge` 触发。
4. 模拟切换失败时旧索引仍可用：`next-switch-rehearsal.yml` 的 pre 模式通过。
5. actionlint 全绿（workflow 改动等 actionlint）。

## 5. 演练顺序（先用两个有依赖的测试 formula）

1. 选两个**非 app** 的简单 formula（如 `ohos-app` 依赖一个基础工具），先验证私有 index + pour 链路。
2. 链路通后，再加入三个新组件（ohos-hap/ohos-device/ohos-app）的编制。
3. 最后才纳入 17 个 desktop formula 的迁移演练。

## 6. 风险与回滚

- **私钥/token**：私有瓶索引不进公开 release；`PRIVATE_ROOT_URL` 若含签名 URL，不得进 PR 注释与日志（沿用 `upstream-diff-comment.sh` 的脱敏约定）。
- **不改公开发布**：所有改动都在 `upload=false` 支路或新工作流；上线前用 actionlint + 一个真实 `bottle-build(upload=false)` run 验证公开路径未受影响。
- **回滚**：本 PR 只新增文件 + 对两个文件做条件分支式最小改动；回滚直接 revert 本 PR，不改 formula bottle block。

## 7. 本机可验证的部分

- `actionlint`（若本机有）或 CI 的 actionlint job：校验新 workflow 语法。
- `bash -n` 校验新增脚本语法。
- 公开路径逐字未改：`git diff` 确认 `bottle.sh`/`bottle-build.yml` 的公开分支无 diff。
- 真机/真实 CI 演练必须在 runner 上完成；本机无法替代，fake 通过不构成发布证明。
