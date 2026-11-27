# 桌面应用清场重构：发版说明

本次重构把全部 17 个 HAP 桌面应用统一到三命令架构（`ohos-app` / `ohos-hap` / `ohos-device`），改为 descriptor-only 交付，并移除旧的 `app-installer` / `<name>-app` 安装轨。

## 用户需要做什么

`brew install` 不再自动装机、不再弹登录、不再启动应用。安装和部署是两步：

```
brew install social4hyq/core/<name>-desktop    # 只交付 HAP 与 descriptor
ohos-app install <name>-desktop                # 显式签名并部署到设备
```

`ohos-app install` 默认不启动应用（加 `--start` 才启动），失败返回非零，没有 pending 队列或后台重试。设备部署的显式性由用户掌控。

## 从旧版升级的清理顺序

删除 tap 文件不会清除用户机器上已装 keg 的 bin/launch 配置和 shell rc 里的旧命令。请按以下顺序显式清理，再装新工具：

1. 卸载旧 app formula：
   ```
   brew uninstall <name>-app          # 例：codex-app、opencode-app、deepseek-harness-app
   brew uninstall app-installer
   ```
2. 清理 shell 配置里对旧命令的引用：`app-installer`、`hap-installer`、`hap-app`、`<name>-app`、`devecocli`（含 `~/.shellrc` / `~/.zshrc` 里的绝对路径启动项）。
3. 安装新工具：
   ```
   brew install social4hyq/core/ohos-app ohos-hap ohos-device
   brew install social4hyq/core/<name>-desktop
   ```
4. 显式部署（按需，不自动）：
   ```
   ohos-app install <name>-desktop
   ```

跳过第 1、2 步会出现旧 bin 占位或命令冲突；本说明不替用户自动完成这些动作。

## 命令对应关系

| 旧 | 新 |
|---|---|
| `<name>-app install` | `ohos-app install <name>-desktop` |
| `<name>-app uninstall` | `ohos-app uninstall <name>-desktop`（默认保留设备数据，`--purge` 清除） |
| `<name>-app start\|stop\|status` | `ohos-app start\|stop\|status <name>-desktop` |
| `hap-installer` / `app-installer`（签名/装机） | `ohos-hap`（签名/验证）、`ohos-device`（设备部署） |
| `brew install` 后自动安装 | 无；显式 `ohos-app install` |

旧的 `app-installer`、`hap-installer`、`hap-app`、`<name>-app` 命令不再提供，不做兼容 shim。

## 数据与兼容性

- bundle ID 保持不变，已装应用沙箱里的数据不因 formula 改名而丢失。
- 不自动重装或降级设备上的应用：是否用新 HAP 覆盖由用户通过 `ohos-app install` 决定。
- 旧资产与旧 release 暂不清理；若新体系发现问题，以新方式修复或增加 `revision` 重发。

## 发布状态

bottle 在 PR 合入时由 CI 构建并发布到公开 atomgit release，formula 的 `bottle do root_url` 指向对应 tag，`brew install` 直接 pour，无需本机源码构建。17 个 `*-desktop` formula 与三个命令组件均已发布 bottle。
