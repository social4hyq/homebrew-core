class Bun < Formula
  desc "Bun — JavaScript runtime for HarmonyOS aarch64 (stable)"
  homepage "https://github.com/oven-sh/bun"
  license "MIT"

  # 主 url = bun 上游源码(git main 分支)。brew install 时 clone 到 buildpath。
  # patch do 自动 apply OHOS patches 到 buildpath(= bun 源码根)。
  stable do
    url "https://gh-proxy.com/https://github.com/oven-sh/bun.git", revision: "e0acad3182a23af828e383a7b419fe82bc0d125f"
    version "1.4.0"
  end

  head "https://github.com/oven-sh/bun.git", branch: "main"

  livecheck do
    url :stable
    regex(/^bun-v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://github.com/social4hyq/homebrew-core/releases/download/bun-v1.4.0"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c79bd44f1efb37ab04e9e98d3f87b7622f814b34cd6d6e3032b1618586b0e8ff"
  end

  # ── 依赖(全部裸名,毕业 harmonybrew/core 时零改动)──
  depends_on "bun-bootstrap" => :build   # 自举:`bun bd` 本身是 bun 脚本
  depends_on "bun-webkit"
  depends_on "llvm@21"        => :build
  depends_on "icu4c@78"
  depends_on "ohos-sdk"                # bun 源码 OHOS 路径用其 sysroot
  depends_on "openssl@3"               # rust-nightly cargo 动态链接 libssl/libcrypto
  depends_on "cmake"          => :build
  depends_on "ninja"          => :build
  depends_on "perl"           => :build
  depends_on "python@3.14"    => :build
  depends_on "ruby"           => :build
  depends_on "gperf"          => :build
  depends_on "node"           => :build   # esbuild postinstall 需要 node

  # Rust nightly(原生 OHOS host 工具链,bun 的 libbun_rust.a 需要)。
  # OHOS 是 Tier 3 target,无预编译 rust-std → bun 用 -Zbuild-std 从源码编,
  # 故需 rust-src 组件(完整 nightly host tarball 自带)。
  # 版本对齐 bun-src/rust-toolchain.toml 的 channel。
  resource "rust-nightly" do
    url "https://static.rust-lang.org/dist/2026-05-06/rust-nightly-aarch64-unknown-linux-ohos.tar.gz"
    sha256 "7e93009ca8eb40fa039ba7fce6d8d6e95646b6459a7582e4ea46308c7db00eb8"
    version "nightly-2026-05-06"
  end

  # rust-src 与 host tarball 分发,bun -Zbuild-std 必需(否则 cargo 报
  # "library/Cargo.lock does not exist, unable to build with the standard library")。
  resource "rust-src" do
    url "https://static.rust-lang.org/dist/2026-05-06/rust-src-nightly.tar.gz"
    sha256 "2bfd8eed73318df568cc5831083b11de986af6da5c66f140b73cf4ae365ceca3"
    version "nightly-2026-05-06"
  end

  # ── OHOS patches(对照 git.rb 的 patch do file 模式)──
  # Homebrew 在 def install 前自动 apply 到 buildpath(= bun 源码根)。
  # 按 PR 顺序声明(pr3 → pr7,顺序敏感)。
  # 每个补丁必须有注释说明目的和上游 issue(Homebrew 审计要求)。
  # 注意:vendor patches(crate-type/ohos-qsort-r)不走 git apply,
  # 而是由 install 步骤 cp 到 bun 的 patches/ 目录,ninja 构建时作为文件依赖应用。
  patch :p1 do
    # pr3-vendor: zstd dep 构建脚本 OHOS 适配
    file "Patches/bun/pr3-vendor/zstd.ts.patch"
  end
  # pr4-build-target: OHOS 交叉编译目标支持(OS="ohos"、triple、sysroot/SDK 配置)
  patch :p1 do
    # build.ts 新增 --ohos-sysroot / --ohos-sdk-root 命令行选项
    file "Patches/bun/pr4-build-target/build.ts.patch"
  end
  patch :p1 do
    # OHOS 链接 libc/pthread/dl 及本地 WebKit ICU,跨编译时跳过 smoke 测试
    file "Patches/bun/pr4-build-target/bun.ts.patch"
  end
  patch :p1 do
    # OHOS musl 缺 GNU 扩展(memmem/getservbyport_r),c-ares config.h 排除
    file "Patches/bun/pr4-build-target/cares.ts.patch"
  end
  patch :p1 do
    # 新增 OS="ohos"、hostCc 字段及 sysroot/SDK/cross-libs/ICU 交叉编译配置
    file "Patches/bun/pr4-build-target/config.ts.patch"
  end
  patch :p1 do
    # OHOS 编译/链接 flag:triple、sysroot、libc++、PIE、8MB 栈、免 zstd 调试
    file "Patches/bun/pr4-build-target/flags.ts.patch"
  end
  patch :p1 do
    # OHOS 一并禁用 MI_NO_SET_VMA_NAME(VMA 标签调试糖)
    file "Patches/bun/pr4-build-target/mimalloc.ts.patch"
  end
  patch :p1 do
    # 新增 aarch64-unknown-linux-ohos 目标,链接器可走签名包装
    file "Patches/bun/pr4-build-target/rust.ts.patch"
  end
  patch :p1 do
    # dep_host_cc 链后串调 binary-sign-tool 签名,OHOS 原生 cargo 用签名链接器
    file "Patches/bun/pr4-build-target/source.ts.patch"
  end
  patch :p1 do
    # 放宽 LLVM 版本至 21–23,新增 OHOS LLVM22 搜索路径与安装提示
    file "Patches/bun/pr4-build-target/tools.ts.patch"
  end
  patch :p1 do
    # 新增 OHOS prebuilt/ICU 选取与交叉编译 CMake 配置(sysroot、libc++ 头、ICU 工具)
    file "Patches/bun/pr4-build-target/webkit.ts.patch"
  end
  patch :p1 do
    # bun scripts/utils.mjs 的 tmpdir() 补 OHOS 分支(回退 /data/local/tmp/$HOME/tmp)
    file "Patches/bun/pr4-build-target/utils.mjs.patch"
  end
  patch :p1 do
    # 新增 ohos-signpost 依赖与 postinstall 探针钩子(补 detect-libc 等依赖)
    file "Patches/bun/pr4-build-target/package.json.patch"
  end
  patch :p1 do
    # 新增 Libc::Ohos 枚举与 triple 解析,平台串报 "ohos"、支持 file:// 注册
    file "Patches/bun/pr4-build-target/compile_target.rs.patch"
  end
  patch :p1 do
    # bun upgrade 下载后缀 OHOS 用 -ohos(musl/android 之外新增一支)
    file "Patches/bun/pr4-build-target/upgrade_command.rs.patch"
  end
  # pr8-upstream-sync: 与 upstream package.json 不一致的 lockfile 同步。
  # 非单独 OHOS 改动 —— upstream package.json 已 bump esbuild 0.25→0.28,
  # 但 bun.lock 仍 pin 0.25.12,这里同步以让 bun install 解析一致。
  patch :p1 do
    file "Patches/bun/pr8-upstream-sync/node-fallbacks-esbuild-lockfile.patch"
  end
  # pr5-ohos-runtime: OHOS 专属运行时替代(syscall 回退、vfork→fork、签名、platform=openharmony)
  patch :p1 do
    # OHOS 下 process.platform 返回 "openharmony"(对齐 Node 命名)
    file "Patches/bun/pr5-ohos-runtime/BunProcess.cpp.patch"
  end
  patch :p1 do
    # OHOS 对外 OS 名映射为 openharmony/OpenHarmony(让 optional deps 解析正确)
    file "Patches/bun/pr5-ohos-runtime/Global.rs.patch"
  end
  patch :p1 do
    # 新增 IS_OHOS / IS_GLIBC,IS_MUSL 把 ohos 一并算入
    file "Patches/bun/pr5-ohos-runtime/env.rs.patch"
  end
  patch :p1 do
    # OHOS 跳过 fchmodat2、getcwd 兜底 "/"、dlopen 前先调签名工具
    file "Patches/bun/pr5-ohos-runtime/lib.rs.patch"
  end
  patch :p1 do
    # OHOS 编译产物调 binary-sign-tool 签名并 chmod 755(seccomp 要求)
    file "Patches/bun/pr5-ohos-runtime/build_command.rs.patch"
  end
  patch :p1 do
    # OHOS 设 $PWD,pipe 标记 socket+非阻塞避免阻塞死循环
    file "Patches/bun/pr5-ohos-runtime/filter_run.rs.patch"
  end
  patch :p1 do
    # OHOS 设 $PWD(bash 走 stat 而非 getcwd),CWD EPERM 静默并回退 $HOME
    file "Patches/bun/pr5-ohos-runtime/run_command.rs.patch"
  end
  patch :p1 do
    # pm scan 合法 OS 列表加入 openharmony
    file "Patches/bun/pr5-ohos-runtime/CommandLineArguments.rs.patch"
  end
  patch :p1 do
    # linkat EEXIST 重试 + EPERM/EACCES 失败回退 copy 安装(OHOS SELinux)
    file "Patches/bun/pr5-ohos-runtime/PackageInstall.rs.patch"
  end
  patch :p1 do
    # OHOS 装包后扫描 .so/.node 调 binary-sign-tool 签名
    file "Patches/bun/pr5-ohos-runtime/PackageInstaller.rs.patch"
  end
  patch :p1 do
    # OHOS 的 node-gyp 临时脚本改用 /system/bin/sh(同 Android)
    file "Patches/bun/pr5-ohos-runtime/PackageManager.rs.patch"
  end
  patch :p1 do
    # symlinkat EPERM/EACCES 建父目录后重试;拆出 ENOENT 单独处理
    file "Patches/bun/pr5-ohos-runtime/TarballStream.rs.patch"
  end
  patch :p1 do
    # linkat EPERM/EACCES 多级回退到 copy(OHOS SELinux 禁硬链)
    file "Patches/bun/pr5-ohos-runtime/Hardlinker.rs.patch"
  end
  patch :p1 do
    # OHOS 生命周期脚本前插 cd(规避 hmdfs getcwd 失败导致 shell 退出)
    file "Patches/bun/pr5-ohos-runtime/lifecycle_script_runner.rs.patch"
  end
  patch :p1 do
    # npm 缓存 linkat 第 3 次失败改拷贝内容(OHOS SELinux EPERM)
    file "Patches/bun/pr5-ohos-runtime/npm.rs.patch"
  end
  patch :p1 do
    # OperatingSystem 枚举新增 OPENHARMONY 位及 CURRENT、名字表
    file "Patches/bun/pr5-ohos-runtime/resolver_hooks.rs.patch"
  end
  patch :p1 do
    # os.type/arch 把 openharmony 归 Linux、arm64 返 aarch64(对齐 Android)
    file "Patches/bun/pr5-ohos-runtime/os.ts.patch"
  end
  patch :p1 do
    # OHOS 改用 fork(seccomp 禁 vfork),exit_group 兜底 _exit,CLOEXEC fd 下限抬到 2
    file "Patches/bun/pr5-ohos-runtime/bun-spawn.cpp.patch"
  end
  patch :p1 do
    # OHOS 关 close_range(返 ENOSYS)、装 SIGSYS 处理器、PATH 加 /system/bin
    file "Patches/bun/pr5-ohos-runtime/c-bindings.cpp.patch"
  end
  patch :p1 do
    # 代码生成 platform 对 OHOS 输出 "openharmony"
    file "Patches/bun/pr5-ohos-runtime/codegen.ts.patch"
  end
  # pr5 版 compile_target.rs 已合并到 pr4 的同名 patch 中,无需单独应用
  patch :p1 do
    # /tmp 只读回退 /data/local/tmp/$HOME/tmp,RLIMIT_NOFILE 最低值,EACCES 视为缺失
    file "Patches/bun/pr5-ohos-runtime/fs.rs.patch"
  end
  patch :p1 do
    # EACCES/EPERM 跳过祖先目录或视为缺失(OHOS 沙箱 "/","/storage" 不可读)
    file "Patches/bun/pr5-ohos-runtime/resolver.rs.patch"
  end
  patch :p1 do
    # openpty dlopen 增加 libc.so 名与 RTLD_DEFAULT 兜底(OHOS openpty 在 libc)
    file "Patches/bun/pr5-ohos-runtime/Terminal.rs.patch"
  end
  patch :p1 do
    # OHOS 关闭 can_use_memfd/use_memfd(同 spawn_process fstat 不可见问题)
    file "Patches/bun/pr5-ohos-runtime/stdio.rs.patch"
  end
  patch :p1 do
    # OHOS no_orphans 用 pidfd + 100ms 轮询检测父进程退出(signalfd 挂死)
    file "Patches/bun/pr5-ohos-runtime/process.rs.patch"
  end
  patch :p1 do
    # OHOS 禁用 memfd stdio 快路径(子进程写后 fstat size=0)
    file "Patches/bun/pr5-ohos-runtime/spawn_process.rs.patch"
  end
  patch :p1 do
    # OHOS 解析 ELF SHT 定位 .bun 段,ftruncate+fsync 防 COW 写丢失
    file "Patches/bun/pr5-ohos-runtime/StandaloneModuleGraph.rs.patch"
  end
  patch :p1 do
    # OHOS SELinux 拒绝 linkat/symlinkat → 加 copy_file_fallback 内容拷贝路径,
    # 并补 OHOS tmpdir 分支(Hardlinker/PackageInstall/TarballStream 共用)
    file "Patches/bun/pr5-ohos-runtime/install-lib.rs.patch"
  end
  # 非单独 OHOS 改动 —— npm manifest invalid 错误消息加文件名(通用调试改进)
  patch :p1 do
    file "Patches/bun/pr8-upstream-sync/npm_jsc-error-msg.patch"
  end
  patch :p1 do
    # OHOS resolver 入口:fs/deps/import-mapper 短路
    file "Patches/bun/pr5-ohos-runtime/resolver-lib.rs.patch"
  end
  patch :p1 do
    # P0 epoll_pwait2:OHOS seccomp SECCOMP_RET_TRAP → SIGSYS 直接杀进程,
    # 上游 ENOSYS/EPERM/EACCES fallback 链无法触发。强制 has_epoll_pwait2=0
    # 跳过首次尝试,直接走 epoll_pwait(毫秒精度)。损失纳秒级超时,保命。
    # Preflight 探针 c13_epoll_pwait2。
    file "Patches/bun/pr5-ohos-runtime/epoll_kqueue.c.patch"
  end
  patch :p1 do
    # OHOS openat2 直接返 ENOSYS(seccomp SIGSYS),放宽若干 fn 可见性
    file "Patches/bun/pr5-ohos-runtime/linux_syscall.rs.patch"
  end
  # pr6-rust-compat: Rust nightly toolchain 兼容性修复(与 OHOS 无关,可独立推上游)
  patch :p1 do
    # errno 转 ExitCode 改用 unsigned_abs()(nightly 类型变更)
    file "Patches/bun/pr6-rust-compat/echo.rs.patch"
  end
  patch :p1 do
    # errno 转 ExitCode 改用 unsigned_abs()(同 echo.rs)
    file "Patches/bun/pr6-rust-compat/which.rs.patch"
  end
  # pr7-shared-cfg-gate: 共享 musl/OHOS 代码路径的 cfg 门控扩展(OHOS libc 是 musl 派生)
  patch :p1 do
    # crash_handler musl 门控扩 ohos,崩溃头 libc 标签输出 "ohos (musl)"
    file "Patches/bun/pr7-shared-cfg-gate/lib.rs.patch"
  end
  patch :p1 do
    # v8 平台 API 块对 OHOS 排除(让其走 musl 回避路径,免 smoke 重定位 fatal)
    file "Patches/bun/pr7-shared-cfg-gate/napi_body.rs.patch"
  end
  patch :p1 do
    # setjmp/longjmp 的 musl 路径扩 ohos,jmp_buf 缩为 32×u64
    file "Patches/bun/pr7-shared-cfg-gate/recover.rs.patch"
  end

  def install
    # buildpath = bun 源码根(patch 已由 Homebrew 自动 apply)。
    # 构建逻辑全部内联(对照 harmonybrew core 的 git.rb —— 无外部脚本)。
    # 依赖均通过 depends_on 声明:llvm@21(签名 clang/lld)、icu4c@78、
    # bun-webkit(JSC 静态库)、bun-bootstrap(L3 driver,自举)。

    # ── Vendor patches(不走 git apply,由 ninja 构建时应用到 vendored crates)──
    tap_patches = Pathname.new(__dir__)/"../../Patches/bun/pr3-vendor"
    (buildpath/"patches/lolhtml").mkpath
    (buildpath/"patches/zstd").mkpath
    cp tap_patches/"crate-type.patch", buildpath/"patches/lolhtml/crate-type.patch"
    cp tap_patches/"ohos-qsort-r.patch", buildpath/"patches/zstd/ohos-qsort-r.patch"

    # ── 修复 config.ts 的 host 平台检测:OHOS 上 process.platform 返回 "openharmony" ──
    inreplace buildpath/"scripts/build/config.ts",
              "plat === \"linux\"",
              "plat === \"linux\" || plat === \"openharmony\""

    llvm     = Formula["llvm@21"]
    webkit   = Formula["bun-webkit"]
    boot     = Formula["bun-bootstrap"]

    # ── 预置 WebKit cache(bun bd 的 fetch 检查 .identity 跳过下载)──
    # webkit.ts.patch 在 source 函数中已做同样操作,但 ninja fetch 步骤可能在
    # source 函数生效前运行,双重保险。
    webkit_ver = "6d586e293f008f0e74e5697611a379b1b24815c9"
    brew_home = Pathname.new(ENV.fetch("HOME"))
    wc = brew_home/".bun/build-cache/webkit-#{webkit_ver[0...16]}-ohos-arm64"
    wc.mkpath
    File.write(wc/".identity", webkit_ver)
    (wc/"lib").mkpath
    %w[libJavaScriptCore.a libWTF.a libbmalloc.a].each do |a|
      ln_sf webkit.lib/a, wc/"lib"/a
    end
    (wc/"include").mkpath
    cd wc/"include" do
      ln_sf webkit.include/"webkit/JavaScriptCore", "JavaScriptCore"
      ln_sf webkit.include/"webkit/wtf", "wtf"
      ln_sf webkit.include/"webkit/bmalloc", "bmalloc"
      cp webkit.include/"webkit/cmakeconfig.h", "cmakeconfig.h"
    end
    %w[libicudata.a libicui18n.a libicuuc.a].each do |a|
      ln_sf Formula["icu4c@78"].opt_lib/a, wc/"lib"/a
    end

    # ── Scaffold build/ohos-icu/{target,host} layout for bun's config.ts ──
    # bun config.ts:1013 defaults ohosIcuDir = <cwd>/build/ohos-icu/target,
    # which is the wrapper's build-icu.sh output path. Brew install never runs
    # build-icu.sh, so point this layout at icu4c@78 formula instead.
    # webkit.ts:472 also resolves hostBin = <ohosIcuDir>/../host/bin for ICU
    # data tools (genrb/genccode/gencmn/pkgdata) — symlink those too.
    icu = Formula["icu4c@78"]
    (buildpath/"build/ohos-icu/target/include").mkpath
    ln_sf icu.opt_include/"unicode", buildpath/"build/ohos-icu/target/include/unicode"
    (buildpath/"build/ohos-icu/target/lib").mkpath
    %w[libicudata.a libicui18n.a libicuuc.a].each do |a|
      ln_sf icu.opt_lib/a, buildpath/"build/ohos-icu/target/lib"/a
    end
    (buildpath/"build/ohos-icu/host/bin").mkpath
    %w[genrb genccode gencmn pkgdata].each do |t|
      ln_sf icu.opt_bin/t, buildpath/"build/ohos-icu/host/bin"/t if (icu.opt_bin/t).exist?
    end

    # ── bun install(更新 lockfile,因 package.json.patch 修改了 devDependencies)──
    # package.json.patch 只改构建必需项(esbuild 版本、ohos-signpost、postinstall),
    # 无需 --ignore-scripts。
    ENV.prepend_path "PATH", boot.opt_bin
    ENV.prepend_path "PATH", llvm.opt_bin
    system "bun", "install"

    # ── Rust nightly(装到 buildpath,仅构建期用。不进 bottle)──
    # OHOS Tier 3 target:bun 用 -Zbuild-std 编 std,需 rust-src(完整 tarball 含)。
    rust_home = buildpath/"rust-nightly"
    rust_home.mkpath
    resource("rust-nightly").stage do
      # host tarball 含 rustc/cargo/rust-std,用 install.sh 装到 rust_home。
      # OHOS 上 bash 路径不在 superenv PATH 中,用 sh 执行避开 shebang 依赖。
      system "sh", "./install.sh", "--prefix=#{rust_home}", "--disable-ldconfig"
    end
    resource("rust-src").stage do
      # rust-src 是独立 target-agnostic tarball,bun -Zbuild-std 需 library/Cargo.lock。
      system "sh", "./install.sh", "--prefix=#{rust_home}", "--disable-ldconfig"
    end

    # ── 给 rust 二进制签名(OHOS 内核拒绝 exec 未签名 ELF,否则 cargo 报 127)──
    sign_tool = Formula["ohos-sdk"].opt_bin/"binary-sign-tool"
    Dir.glob(rust_home/"**/*").each do |f|
      next unless File.file?(f) && !File.symlink?(f)
      next unless File.read(f, 4, mode: "rb") == "\x7fELF"
      tmp = "#{f}.unsigned"
      mv f, tmp
      system sign_tool, "sign", "-selfSign", "1", "-inFile", tmp, "-outFile", f
      chmod 0755, f
      rm tmp
    end

    # ── 构建环境(PATH + env)──
    # llvm@21 的 lld 运行时依赖 libxml2/zlib,brew superenv 剥离了系统库路径,
    # 显式注入让 ld.lld 能找到(与 bun-webkit 一致)。
    ENV.prepend_path "LD_LIBRARY_PATH", Formula["libxml2"].opt_lib.to_s
    ENV.prepend_path "LD_LIBRARY_PATH", Formula["zlib"].opt_lib.to_s
    # rust-nightly cargo NEEDED libssl.so/libcrypto.so(brew openssl@3),
    # 不注入会 musl 启动期 "Error relocating ... symbol not found" → exit 127。
    ENV.prepend_path "LD_LIBRARY_PATH", Formula["openssl@3"].opt_lib.to_s
    # llvm@21 只有 llvm-strip,bun 构建脚本需要 strip。
    # cc/c++ 必须签链接产物:OHOS 内核拒绝 exec 未签名 ELF,cargo 的 build-script-build
    # 二进制本机执行 → "Permission denied (os error 13)"。clang-sign 链接后自动跑
    # binary-sign-tool;只签 link 输出,跳过 -c/-E/-S/-M/-MM(.o 带 .codesign 段会让
    # 最终二进制 ".codesign section already exists",binary-sign-tool 拒签)。
    mkdir_p buildpath/".bin"
    ln_sf llvm.opt_bin/"llvm-strip", buildpath/".bin/strip"
    clang_sign = buildpath/".bin/clang-sign"
    clang_sign.write <<~SHELL
      #!/bin/sh
      set -e
      "#{llvm.opt_bin}/clang" "$@"
      rc=$?
      [ $rc -ne 0 ] && exit $rc
      out=""; prev=""
      for arg in "$@"; do
        [ "$prev" = "-o" ] && out="$arg"
        prev="$arg"
      done
      has_link=1
      for a in "$@"; do
        case "$a" in -c|-E|-S|-M|-MM) has_link=0 ;; esac
      done
      [ "$has_link" = "1" ] || exit 0
      [ -z "$out" ] && [ -f a.out ] && out=a.out
      [ -n "$out" ] && [ -f "$out" ] || exit 0
      magic=$(od -An -N4 -tx1 "$out" 2>/dev/null | tr -d ' \\n')
      [ "$magic" = "7f454c46" ] || exit 0
      readelf -S "$out" 2>/dev/null | grep -q '\\.codesign' && exit 0
      tmp="${out}.unsigned.$$"
      mv -f "$out" "$tmp"
      if "#{Formula["ohos-sdk"].opt_bin}/binary-sign-tool" sign -selfSign 1 -inFile "$tmp" -outFile "$out" >/dev/null 2>&1; then
        chmod +x "$out"
        rm -f "$tmp"
      else
        mv -f "$tmp" "$out"
      fi
      exit 0
    SHELL
    chmod 0755, clang_sign
    clang_sign_pp = buildpath/".bin/clang++-sign"
    clang_sign_pp.write clang_sign.read.gsub("/clang\"", "/clang++\"")
    chmod 0755, clang_sign_pp
    ln_sf clang_sign,    buildpath/".bin/cc"
    ln_sf clang_sign_pp, buildpath/".bin/c++"
    # bun flags.ts 期望 ohosCrossLibs 下有 libcxx/include/v1/ 和 libcxxabi/include/。
    # llvm@21 的对应头文件在 include/aarch64-linux-ohos/c++/v1/。
    # 在 buildpath 下创建匹配布局,覆盖 OHOS_LLVM_PREFIX 让 build.ts 找到。
    # bun 构建系统在 OHOS 模式会用 -nostdinc++ 并查找 build/ohos-cross-libs/。
    # 预创该目录软链到 llvm@21 的头文件和库,满足 flags.ts 的 include/link 路径。
    ohos_cross = buildpath/"build/ohos-cross-libs"
    (ohos_cross/"libcxx/include").mkpath
    (ohos_cross/"libcxxabi").mkpath
    ln_sf llvm.opt_include/"aarch64-linux-ohos/c++/v1", ohos_cross/"libcxx/include/v1"
    ln_sf llvm.opt_include/"aarch64-linux-ohos/c++/v1", ohos_cross/"libcxxabi/include"
    %w[libcxx libcxxabi libunwind].each do |d|
      (ohos_cross/d/"lib").mkpath
      Dir[llvm.opt_lib/"aarch64-linux-ohos/*.a"].each do |a|
        ln_sf a, ohos_cross/d/"lib"/File.basename(a)
      end
    end
    ENV.prepend_path "PATH", buildpath/".bin"
    # bootstrap bun 进 PATH:`bun bd` 本身是 bun 脚本,需先有能跑的 bun。
    ENV.prepend_path "PATH", boot.opt_bin
    ENV.prepend_path "PATH", llvm.opt_bin
    ENV.prepend_path "PATH", rust_home/"bin"
    ENV["CARGO_HOME"]    = (rust_home/"cargo").to_s
    ENV["RUSTUP_HOME"]   = rust_home.to_s
    # superenv 注入的 rustc_wrapper shim 是 #!/bin/bash,OHOS 无 /bin/bash → exec ENOENT。
    ENV.delete("RUSTC_WRAPPER")
    # cargo 拉 crates.io 时需 CA bundle(OHOS musl 无系统 CA store)。
    ca_bundle = HOMEBREW_PREFIX/"etc/ca-certificates/cert.pem"
    ENV["SSL_CERT_FILE"]  = ca_bundle.to_s
    ENV["CURL_CA_BUNDLE"] = ca_bundle.to_s
    # rust-toolchain.toml 锁的 channel;OHOS target 走 -Zbuild-std(pr4 patch)
    ENV["RUSTUP_TOOLCHAIN"] = "nightly-2026-05-06"
    ENV["OHOS_LLVM_PREFIX"]  = llvm.opt_prefix.to_s
    ENV["OHOS_WEBKIT_ROOT"]  = webkit.opt_prefix.to_s
    # bun rust.ts:647/source.ts:1411 用此 env 替换 OHOS target link 的 linker。
    ENV["OHOS_BUN_SIGNING_LINKER"] = clang_sign_pp.to_s
    # cargo 主机 build-script 链接走 CC(cc-rs crate);未签名则 build-script-build
    # exec 时 EACCES。CC 走 clang-sign,链接产物自动签名。
    ENV["CC"]  = clang_sign.to_s
    ENV["CXX"] = clang_sign_pp.to_s

    # ── 构建:bun scripts/build.ts(即 `bun bd` 的等价调用)──
    # --os=ohos --arch=aarch64 触发 bun 源码里的 OHOS 编译路径(pr4+pr5 patch)。
    sysroot = Formula["ohos-sdk"].opt_prefix/"native/sysroot"
    system "bun", "scripts/build.ts",
           "--profile=release", "--os=ohos", "--arch=aarch64", "--canary=off",
           "--ohos-sdk-root=#{Formula["ohos-sdk"].opt_prefix}",
           "--ohos-sysroot=#{sysroot}"

    # release profile 产物名是 `bun-profile`(unstripped, ~455MB) + `bun`
    # (stripped, ~105MB)。优先 stripped 版本,体积小且 ready-to-run。
    out = buildpath/"build/release/bun"
    odie "bun binary missing after build: #{out}" unless out.exist?
    # OHOS 内核拒绝 exec 未签名 ELF。bun 构建系统不自带签名(签名工具
    # 是 OHOS-specific),故 install 后显式签。
    sign_tool = Formula["ohos-sdk"].opt_bin/"binary-sign-tool"
    unsigned = "#{out}.unsigned"
    mv out, unsigned
    system sign_tool, "sign", "-selfSign", "1", "-inFile", unsigned, "-outFile", out
    chmod 0755, out
    rm unsigned
    bin.install out => "bun"
  end

  def caveats
    <<~EOS
      Bun (stable, #{version}) for HarmonyOS aarch64.
      Built via L4 self-bootstrap (bun-bootstrap → bun bd).
    EOS
  end

  test do
    assert_match "4294967296", shell_output("#{bin}/bun -e 'console.log(2**32)'")
    assert_match version.to_s,  shell_output("#{bin}/bun --version")
  end
end
