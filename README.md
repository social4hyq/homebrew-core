# social4hyq/homebrew-core

HarmonyOS (OHOS aarch64) Homebrew tap。收录在鸿蒙系统上从源码构建的 formula 及其预编译 bottle，作为 [Harmonybrew](https://atomgit.com/Harmonybrew) 官方 core 的先行验证仓库。

## 仓库定位

最终目标是把本仓库中稳定下来的 formula 合入 [Harmonybrew 官方 core](https://atomgit.com/Harmonybrew)。当前仍未合入，原因有二：

1. **上游阻塞**：`bun` 与 `rust` 的官方 OHOS aarch64 版本尚未发布。本仓库自带的 `llvm@21` 工具链与 `bun-bootstrap` 预编译产物，是在上游缺失前提下的本机自举过渡方案。一旦 `bun` / `rust` 官方版发布，相关 formula 需要切换到上游产物，过渡层应当退出。
2. **验证范围有限**：现有 formula 在开发机上完成了构建、安装与基础 smoke 测试，但尚未在多样的 HarmonyOS 设备与版本上覆盖测试。稳定性需要更长时间观察才能确认。

在这两项前提解决之前，本仓库独立维护，不合入官方 core。

## Formulae

| Formula | 版本 | 说明 |
|---|---|---|
| `llvm@21` | 21.1.8 | OHOS 补丁版 clang + lld + multiarch runtime libs |
| `icu4c@78` | 78.3 | Unicode 库(用 llvm@21 重编，消除 stale ABI 标签) |
| `bun-bootstrap` | 1.4.0-a4cd4d2 | 预编译 bun，自举构建用 |
| `bun-webkit` | 6d586e293f | JavaScriptCore / WTF / bmalloc 静态库(bun 专用 WebKit fork) |
| `bun` | 1.3.14 | bun 稳定版 |
| `bun-canary` | 1.4.0-a4cd4d2 | bun canary 滚动版(`keg_only`，不进入 PATH) |
| `bun-pty` | 0.4.10 | bun-pty 的 `librust_pty.so`(portable-pty nix→0.31，源码构建 + 签名，`keg_only`) |
| `lightningcss` | 1.30.1 | `liblightningcss_node.so`(`lightningcss_node` crate 源码构建 + 签名，`keg_only`) |
| `tailwindcss-oxide` | 4.1.11 | `libtailwind_oxide.so`(`tailwind-oxide` crate 源码构建 + 签名，`keg_only`) |
| `opencode` | 1.17.8 | OpenCode(AI 编码代理 CLI，bun compile 单文件 + 嵌入 Web UI) |

## 依赖图

```
bun            ──build──► bun-bootstrap
  ├─► bun-webkit ──► llvm@21, icu4c@78
  ├─► llvm@21
  └─► icu4c@78

bun-canary     ──build──► bun-bootstrap    (其余同 bun)

bun-pty          ──build──► rust, ohos-sdk
lightningcss     ──build──► rust, ohos-sdk
tailwindcss-oxide ──build──► rust, ohos-sdk

opencode       ──build──► bun, bun-pty, lightningcss, tailwindcss-oxide
  ├─► llvm@21               (llvm-objcopy 剥 .codesign 段后重签)
  ├─► ohos-sdk              (binary-sign-tool 签 node_modules 中的 .so/.node)
  ├─► node                  (node-gyp 头)
  └─► python@3.14           (构建期)

llvm@21        ──► ohos-sdk
```

## 安装

```bash
brew tap social4hyq/core https://github.com/social4hyq/homebrew-core.git
brew install llvm@21
brew install bun
brew install bun-canary        # keg_only，提供 bun-canary 命令
brew install bun-webkit
brew install opencode          # 自动拉入 bun / bun-pty / lightningcss / tailwindcss-oxide
```

## 设计约定

1. **结构与官方 core 1:1**：`Formula/<字母>/<name>.rb`；依赖写裸名(`depends_on "llvm@21"`)，合入官方 core 时 formula 正文零改动，只改 bottle `root_url`。
2. **OHOS 身份由 tap 承载，formula 名不加 `ohos-` 前缀**：与 harmonybrew core 现有惯例(`icu4c@78`、`rust`、`ohos-sdk`)保持一致。
3. **构建编排与 formula 同仓**：`build-bun.sh` / `scripts/` / `ohos-patches/` 放在 `build-scripts/`，`bun` formula 的 `url` 指向本仓库 archive，构建时直接取用。

## 合入官方 core 的判定条件

一个 formula 只有同时满足以下条件才会发起合入 PR：

- 上游对应官方版本已发布(对 `bun`、`rust` 等当前被自举绕过的组件而言)；或上游不计划发布但本仓库验证周期足够长。
- 在多台 HarmonyOS 设备、多个系统版本上完成覆盖测试，无回归。
- bottle 在本仓库已稳定运行一段时间，无频繁改动。

在此之前，formula 留在本仓库独立迭代。

## 目录结构

```
Formula/                    # 配方(.rb)
  l/llvm@21.rb              # OHOS 补丁 LLVM 工具链
  i/icu4c@78.rb             # Unicode 库(验证用 llvm@21 重编)
  b/bun-bootstrap.rb        # 预编译自举 bun
  b/bun-webkit.rb           # JavaScriptCore 静态库
  b/bun.rb                  # bun 稳定版
  b/bun-canary.rb           # bun canary(keg_only)
  b/bun-pty.rb              # bun-pty 的 librust_pty.so
  l/lightningcss.rb         # lightningcss Node native binding
  t/tailwindcss-oxide.rb    # tailwindcss/oxide Node native binding
  o/opencode.rb             # OpenCode CLI(bun compile 单文件)
Patches/                    # 所有补丁，按 formula 名分子目录
  llvm@21/code-sign.patch
  bun-webkit/*.patch
  lightningcss/*.patch      # OHOS target + platform 分支
  opencode/*.patch          # OHOS target + esbuild/rolldown/vite 适配
  bun/                      # bun 源码补丁(按 PR 分组，扁平存放)
    pr3-vendor/*.patch
    pr4-build-target/*.patch
    pr5-ohos-runtime/*.patch
    pr6-rust-compat/*.patch
    pr7-shared-cfg-gate/*.patch
build-scripts/              # bun 构建编排(build-bun.sh + scripts/ + ohos-patches/)
```

**结构对照 harmonybrew/homebrew-core 的 git.rb**：formula 主 `url` 指向上游源码，`patch do file` 自动 apply 补丁，`def install` 内联全部构建逻辑(无外部脚本)。依赖通过 `depends_on` 声明，各组件由对应 formula 提供：

- 签名 → llvm@21 的 `sign_dir` + lld `--code-sign`
- libc++ 布局 → llvm@21 的 `build_multiarch_runtimes`
- ICU → icu4c@78 formula 直接产出
- WebKit cache → bun-webkit formula 的 cmake build
- bootstrap bun → bun-bootstrap formula
