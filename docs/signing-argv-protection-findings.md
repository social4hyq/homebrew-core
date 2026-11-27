# PR 2a：签名密码 argv 保护可行性验证（实测报告）

本文是压测 P0 第 1 条的验证结论。目标：确认能否用受保护输入（fd/stdin/keychain）替代 `sign-hap.cjs` 当前把 `-keyPwd`/`-keystorePwd` 明文放 argv 的做法。

## 结论（明确，不可两头下注）

**在当前 SDK 版本（`ohos-sdk-toolchains` 26.0.0.38 的 `hap-sign-tool`）上，无法用受保护 fd/stdin 替代 argv 密码。** `-pwdInputMode 1` 是 **TTY 交互输入**，不是 pipe/stdin 输入——在无 TTY 的 CI/自动化场景不可用。因此：

- 不能声称"改用 `-pwdInputMode 1` 就解决 argv 泄漏"——这是错误的。
- 当前唯一自动化可行的路径仍是 argv 密码（mode 0），其"同用户进程可见"的残余风险真实存在，必须显式记录，不能粉饰。
- 目标架构 §5.1"密码绝不进 argv"的条款，在当前 SDK 下**无法完全达成**；应改为"优先尝试受保护后端；当前 SDK 无此能力时记录残余风险并 fail-closed 于无材料路径，不自动弹登录"。

## 实测证据（本机，`hap-sign-tool -help`）

`sign-app[options]` 帮助原文：
```
-pwdInputMode : Selecting the password input mode. The value 0 represents entering the password by the
command line parameter, and the value 1 represents interactive password input. It is an optional parameter, with
a default value of 0.
```
（同样字段存在于 `generate-keypair`/`generate-csr` 等命令。）

## 实测行为

| 测试 | 命令条件 | 结果 | 判定 |
|---|---|---|---|
| mode 0（当前做法） | `-pwdInputMode 0 -keyPwd wrong -keystorePwd wrong` + 假材料 | 走到 `CERTIFICATE_ERROR`（证书链无效），说明密码已作为参数被接受 | argv 路径可用 |
| mode 1 + pipe/stdin | `-pwdInputMode 1`，`printf 'pass\npass\n' \| ...` | `ERROR - failed to get keystorePwd, please check terminal permissions` | **pipe/stdin 喂不进，需真实 TTY** |

结论：mode 1 调用的是 `getpass`-类 TTY 读取（需终端权限），不是从 stdin 读。自动化（无 TTY）场景无法用它喂密码，也无法用 fd 传递。

## 对方案的影响与修正

1. **修订 §5.1 的绝对化表述**：把"密码绝不进 argv；若工具只支持明文 argv 则拒绝该后端"改为——
   - 首选：外部材料 + 用户原路径 + 显式 `--profile`/`--keystore`，密码来源由用户控制；
   - 当前 SDK 自动化路径仍为 argv，残余风险写入已知限制；
   - 不因密码问题自动 `auth login` 或建用户会话。
2. **不把 mode 1 写成解决方案**：它是 TTY 交互，只适合用户在交互终端手动签名，不适合 `ohos-app install` 的自动化路径。
3. **跟进项（需上游）**：推动 `hap-sign-tool` 支持从受保护 fd / stdin / 环境变量间接引用读密码；在其支持前，本项不能作为"已解决"Gate。
4. **CI 验收调整**：真实签名测试仍必须做（加密材料 + 无泄漏日志审计 + 设备接受），但不能以"已消除 argv"为通过条件；改为"已记录且 Won't-fix-on-current-SDK"。

## 本机未能验证的部分

- 真实加密 keystore/profile 的解码与签名（无测试材料）；
- `bm install` 后设备是否接受签名结果（无真机）；
- PTY（`script` 命令）下 mode 1 的完整交互流程——即使可用也只是手动路径，不改变自动化结论。

fake/帮助文本验证不构成发布证明；真实签名与真机验收必须在 CI/真机完成。
