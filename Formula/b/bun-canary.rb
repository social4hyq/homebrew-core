class BunCanary < Formula
  desc "Bun — JavaScript runtime for HarmonyOS aarch64 (canary, rolling)"
  homepage "https://github.com/oven-sh/bun"
  license "MIT"

  # canary:主 url = bun.git canary 分支。keg_only,不毕业(对照 rust nightly 惯例)。
  stable do
    url "https://github.com/oven-sh/bun.git", branch: "canary"
    version "1.4.0-a4cd4d2"
  end

  head "https://github.com/oven-sh/bun.git", branch: "canary"

  livecheck do
    url "https://github.com/oven-sh/bun/releases/latest"
    regex(/bun-v?canary\.?(.+)/i)
  end

  # bottle: 尚未出,先 build-from-source。出 bottle 时取消注释。
  #   bottle do
  #     root_url "https://github.com/social4hyq/homebrew-core/releases/download/bun-canary-v1.4.0-a4cd4d2"
  # sha256 cellar: :any_skip_relocation, arm64_ohos: "0000000000000000000000000000000000000000000000000000000000000000"
  # end

  keg_only "canary build; use `bun` for the stable command"

  depends_on "bun-bootstrap" => :build
  depends_on "bun-webkit"
  depends_on "llvm@21"        => :build
  depends_on "icu4c@78"
  depends_on "ohos-sdk"
  depends_on "cmake"          => :build
  depends_on "ninja"          => :build
  depends_on "perl"           => :build
  depends_on "python@3.14"    => :build
  depends_on "ruby"           => :build
  depends_on "gperf"          => :build

  # Rust nightly(原生 OHOS host 工具链,同 bun.rb)
  resource "rust-nightly" do
    url "https://static.rust-lang.org/dist/2026-05-06/rust-nightly-aarch64-unknown-linux-ohos.tar.gz"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    version "nightly-2026-05-06"
  end

  # ── OHOS patches(对照 git.rb 的 patch do file 模式)──
  # Homebrew 在 def install 前自动 apply 到 buildpath(= bun 源码根)。
  # 按 PR 顺序声明(pr3 → pr7,顺序敏感)。
  # 每个补丁必须有注释说明目的和上游 issue(Homebrew 审计要求)。
  patch :p1 do
    # pr3-vendor: lolhtml crate-type 改 staticlib(OHOS 无动态链接支持)
    file "Patches/bun/pr3-vendor/crate-type.patch"
  end
  patch :p1 do
    # pr3-vendor: zstd qsort_r 在 OHOS musl 不可用
    file "Patches/bun/pr3-vendor/ohos-qsort-r.patch"
  end
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
    # tmpdir() 优先用 $TMPDIR,适配 OHOS 只读 /tmp(erofs)
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
  patch :p1 do
    # pr5 版:Libc::Ohos 平台串改用 "openharmony"(覆盖 pr4,对齐 Node)
    file "Patches/bun/pr5-ohos-runtime/compile_target.rs.patch"
  end
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
    # OHOS openat2 直接返 ENOSYS(seccomp SIGSYS),放宽若干 fn 可见性
    file "Patches/bun/pr5-ohos-runtime/linux_syscall.rs.patch"
  end
  # pr6-rust-compat: Rust nightly toolchain 兼容性修复(与 OHOS 无关,可独立推上游)
  patch :p1 do
    # 适配 nightly:Type::info().size 改为 Type::size().expect()
    file "Patches/bun/pr6-rust-compat/multi_array_list.rs.patch"
  end
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
    # 构建逻辑内联(同 bun.rb,只差 --canary=on + 装为 bun-canary)。
    llvm     = Formula["llvm@21"]
    webkit   = Formula["bun-webkit"]
    boot     = Formula["bun-bootstrap"]

    rust_home = libexec/"rust-nightly"
    rust_home.mkpath
    resource("rust-nightly").stage do
      system "./install.sh", "--prefix=#{rust_home}", "--disable-ldconfig"
    end

    ENV.prepend_path "PATH", boot.opt_bin
    ENV.prepend_path "PATH", llvm.opt_bin
    ENV.prepend_path "PATH", rust_home/"bin"
    ENV["CARGO_HOME"]    = (rust_home/"cargo").to_s
    ENV["RUSTUP_HOME"]   = rust_home.to_s
    ENV["RUSTUP_TOOLCHAIN"] = "nightly-2026-05-06"
    ENV["OHOS_LLVM_PREFIX"]  = llvm.opt_prefix.to_s
    ENV["OHOS_WEBKIT_ROOT"]  = webkit.opt_prefix.to_s

    system "bun", "scripts/build.ts",
           "--profile=release", "--os=ohos", "--arch=aarch64", "--canary=on"

    out = buildpath/"build/release/bun-release"
    odie "bun binary missing after build: #{out}" unless out.exist?
    bin.install out => "bun-canary"
  end

  def caveats
    <<~EOS
      Bun canary (#{version}) for HarmonyOS aarch64.
      Rolling canary build — keg-only, provides `bun-canary`.
      For the stable command, install `bun` instead.
      Note: canary does NOT graduate to harmonybrew/core.
    EOS
  end

  test do
    assert_match "4294967296", shell_output("#{bin}/bun-canary -e 'console.log(2**32)'")
  end
end
