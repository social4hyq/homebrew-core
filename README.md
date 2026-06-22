# social4hyq/homebrew-core

HarmonyOS (OHOS aarch64) Homebrew tap — **验证场**。所有 formula 先在此充分验证,成熟后毕业合入 [`harmonybrew/homebrew-core`](https://gitcode.com/Harmonybrew/homebrew-core)(官方 core)。

## 设计原则

1. **结构与官方 core 1:1**:`Formula/<字母>/<name>.rb`,依赖写**裸名**(`depends_on "llvm@21"` 而非 `"social4hyq/.../llvm@21"`)。毕业时 formula 正文零改动,只改 bottle `root_url`。
2. **OHOS 身份由 tap 承载,不加 `ohos-` 前缀**:与 harmonybrew/core 现有惯例(`icu4c@78`、`rust`、`ohos-sdk`)一致。
3. **构建编排与 formula 同仓**:`build-bun.sh` + `scripts/` + `ohos-patches/` 放在 `build-scripts/`,`bun` formula 的 `url` 指向本仓库 archive,构建时直接取用。

## Formulae

| Formula | 版本 | 说明 | 毕业状态 |
|---|---|---|---|
| `llvm@21` | 21.1.8 | OHOS 补丁版 clang + lld + multiarch runtime libs | 验证中 |
| `icu4c@78` | 78.3 | Unicode 库(用 llvm@21 重编,消除 stale ABI 标签) | **已在官方 core**(本仓仅验证新 bottle) |
| `bun-bootstrap` | 1.4.0-a4cd4d2 | 预编译 bun,自举构建用(L3 driver) | 验证中 |
| `bun-webkit` | 6d586e293f | JavaScriptCore/WTF/bmalloc 静态库(bun 专用 fork) | 验证中 |
| `bun` | 1.3.14 | bun 稳定版 | 验证中(毕业目标) |
| `bun-canary` | 1.4.0-a4cd4d2 | bun canary 滚动版(`keg_only`,**不毕业**) | 仅验证 |
| `bun-pty` | 0.4.10 | bun-pty 的 `librust_pty.so`(portable-pty nix→0.31,源码构建+签名,`keg_only`) | 验证中 |

## 依赖图

```
bun            ──build──► bun-bootstrap
  ├─► bun-webkit ──► llvm@21, icu4c@78
  ├─► llvm@21
  └─► icu4c@78

 bun-canary     ──build──► bun-bootstrap   (其余同 bun)

bun-pty        ──build──► rust
  └─► ohos-sdk          (binary-sign-tool 签名 .so)

llvm@21        ──► ohos-sdk
```

## 安装

```bash
brew tap social4hyq/core https://github.com/social4hyq/homebrew-core.git
brew install bun             # 稳定版
brew install bun-canary      # canary(keg_only,提供 bun-canary 命令)
brew install llvm@21
brew install bun-webkit
```

## 毕业一个 formula 到官方 core

```bash
# 1. 复制 formula 文件(正文零改动)
cp Formula/<l>/<name>.rb  /path/to/harmonybrew-homebrew-core/Formula/<l>/

# 2. 改 bottle root_url → 官方 core 的 releases,重出 bottle

# 3. 依赖写法已是裸名,无需改动

# 4. 发 PR 到 harmonybrew/homebrew-core
```

## 目录结构

```
Formula/                  # 配方(.rb)
  l/llvm@21.rb            # OHOS 补丁 LLVM 工具链
  i/icu4c@78.rb           # Unicode 库(验证用 llvm@21 重编)
  b/bun-bootstrap.rb      # 预编译自举 bun
  b/bun-webkit.rb         # JavaScriptCore 静态库
  b/bun.rb                # bun 稳定版
  b/bun-canary.rb         # bun canary(不毕业)
Patches/                  # 所有补丁,按 formula 名分子目录
  llvm@21/code-sign.patch
  bun-webkit/*.patch
  bun/                    # bun 源码补丁(按 PR 分组,扁平存放)
    pr3-vendor/*.patch
    pr4-build-target/*.patch
    pr5-ohos-runtime/*.patch
    pr6-rust-compat/*.patch
    pr7-shared-cfg-gate/*.patch
```

**结构对照 harmonybrew/homebrew-core 的 git.rb**:formula 主 `url` = 上游源码,
`patch do file` 自动 apply 补丁,`def install` 内联全部构建逻辑(无外部脚本)。
依赖通过 `depends_on` 声明,各组件由对应 formula 提供:
- 签名 → llvm@21 的 `sign_dir` + lld `--code-sign`
- libc++ 布局 → llvm@21 的 `build_multiarch_runtimes`
- ICU → icu4c@78 formula 直接产出
- WebKit cache → bun-webkit formula 的 cmake build
- bootstrap bun → bun-bootstrap formula
