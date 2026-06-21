class BunWebkit < Formula
  desc "Bun WebKit fork (JavaScriptCore/WTF/bmalloc) static archives for HarmonyOS aarch64"
  homepage "https://github.com/oven-sh/bun"
  license "BSD-3-Clause"           # JavaScriptCore (JSCOnly port)

  # WebKit 源码(oven-sh/WebKit 官方仓库)。
  # commit 对齐 bun-src/scripts/build/deps/webkit.ts 的 WEBKIT_VERSION。
  # 用 oven-sh 而非个人 fork(springmin/WebKit):6d586e293f 原本就在 oven-sh,
  # 且 OHOS 适配靠 bun 侧的 webkit.ts.patch,无需改 WebKit 源码。
  # 无对应 tag,直接用 commit sha 作 revision(Homebrew git url 支持)。
  # 验证阶段:先用本地已有源码(/ohos-bun-webkit/webkit-src),跳过 git clone。
  # 毕业时改回 oven-sh/WebKit.git。
  stable do
    url "file:///storage/Users/currentUser/HarmonyPC/Software/ohos-bun-webkit/webkit-src"
    version "6d586e293f"
  end

  # WebKit 版本必须与 bun-src/scripts/build/deps/webkit.ts 的 WEBKIT_VERSION 一致,
  # 不能自动 bump,否则与 bun 的 ABI 不匹配。
  no_autobump! because: "pinned to bun's WEBKIT_VERSION"

  bottle do
    root_url "https://github.com/social4hyq/homebrew-core/releases/download/bun-webkit-v6d586e293f"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b24f668229c547b3677a87e2cd6948f0b83d6654e0e1dba2b3283d7fafbbf682"
  end

  keg_only "WebKit static archives are consumed in-tree by Bun, not linked system-wide"

  depends_on "cmake"        => :build
  depends_on "ninja"        => :build
  depends_on "perl"         => :build
  depends_on "python@3.14"  => :build
  depends_on "ruby"         => :build
  depends_on "gperf"        => :build
  depends_on "llvm@21"
  depends_on "icu4c@78"
  depends_on "ohos-sdk"            # JSC 交叉编译用其 sysroot
  # llvm@21 的 lld 运行时依赖 libxml2/zlib;显式声明让 superenv 注入库路径。
  depends_on "libxml2" => :build
  depends_on "zlib"    => :build

  def install
    # 验证阶段:用本地源码(改回 oven-sh/WebKit url 后,此段删掉)。
    # `file://` URL 经 brew 的 download strategy 处理时 buildpath 为空,手动 copy。
    local_src = "/storage/Users/currentUser/HarmonyPC/Software/ohos-bun-webkit/webkit-src"
    if File.directory?(local_src) && !File.exist?(buildpath/"CMakeLists.txt")
      ohai "Copying local WebKit source to buildpath..."
      FileUtils.cp_r "#{local_src}/.", buildpath, preserve: true
    end

    # llvm@21 的 lld 运行时依赖 libxml2/zlib,brew superenv 可能剥离 LD_LIBRARY_PATH,
    # 显式注入库搜索路径(参照 icu4c@78 的经验)。
    ENV.prepend_path "LD_LIBRARY_PATH", Formula["libxml2"].opt_lib.to_s
    ENV.prepend_path "LD_LIBRARY_PATH", Formula["zlib"].opt_lib.to_s

    clang    = Formula["llvm@21"].opt_bin/"clang"
    clangxx  = Formula["llvm@21"].opt_bin/"clang++"
    sysroot  = "#{Formula["ohos-sdk"].opt_prefix}/native/sysroot"

    # OHOS 交叉编译 flags(对齐 bun-src/scripts/build/deps/webkit.ts 的 cfg.ohos 分支)。
    target_flag = "--target=aarch64-linux-ohos"
    sysroot_flag = "--sysroot=#{sysroot}"
    icu_include = "-I#{Formula["icu4c@78"].opt_include}"

    cxxflags = [
      target_flag, sysroot_flag, "-D__MUSL__",
      "-mbranch-protection=none", "-mno-outline-atomics",
      "-nostdinc++ -I#{Formula["llvm@21"].opt_include}/aarch64-linux-ohos/c++/v1",
      icu_include, "-fno-c++-static-destructors", "-std=gnu++23",
    ].join(" ")

    cflags = [
      target_flag, sysroot_flag, "-D__MUSL__",
      "-mbranch-protection=none", "-mno-outline-atomics", icu_include,
    ].join(" ")

    # lib/ 目录(对齐 setup-webkit-cache.sh 期望的布局)
    libpath = lib
    mkdir buildpath/"build" do
      args = %W[
        -G Ninja
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=#{prefix}
        -DCMAKE_C_COMPILER=#{clang}
        -DCMAKE_CXX_COMPILER=#{clangxx}
        -DCMAKE_C_FLAGS=#{cflags}
        -DCMAKE_CXX_FLAGS=#{cxxflags}
        -DCMAKE_EXE_LINKER_FLAGS=-L#{Formula["llvm@21"].opt_lib}/aarch64-linux-ohos -Wl,--code-sign
        -DPORT=JSCOnly
        -DENABLE_STATIC_JSC=ON
        -DUSE_THIN_ARCHIVES=OFF
        -DENABLE_FTL_JIT=ON
        -DUSE_BUN_JSC_ADDITIONS=ON
        -DUSE_BUN_EVENT_LOOP=ON
        -DENABLE_BUN_SKIP_FAILING_ASSERTIONS=ON
        -DALLOW_LINE_AND_COLUMN_NUMBER_IN_BUILTINS=ON
        -DENABLE_REMOTE_INSPECTOR=ON
        -DENABLE_MEDIA_SOURCE=OFF
        -DENABLE_MEDIA_STREAM=OFF
        -DENABLE_WEB_RTC=OFF
        -DCMAKE_SYSTEM_NAME=Linux
        -DCMAKE_SYSTEM_PROCESSOR=aarch64
        -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY
        -DCMAKE_FIND_ROOT_PATH=#{sysroot};#{Formula["icu4c@78"].opt_prefix}
        -DCMAKE_PREFIX_PATH=#{Formula["icu4c@78"].opt_prefix}
        -DICU_ROOT=#{Formula["icu4c@78"].opt_prefix}
        -DICU_INCLUDE_DIR=#{Formula["icu4c@78"].opt_include}
        -DCMAKE_HAVE_THREADS_LIBRARY=1
      ]
      system "cmake", *args, buildpath.to_s
      system "ninja", "-j", ENV.make_jobs.to_s, "JavaScriptCore", "WTF", "bmalloc"
    end

    # 产物:libJavaScriptCore.a / libWTF.a / libbmalloc.a + 头文件
    # (cmake JSCOnly target 输出在 build/lib/)
    lib.install Dir["build/lib/libJavaScriptCore.a", "build/lib/libWTF.a", "build/lib/libbmalloc.a"]
    # 三个组件的顶层目录都叫 Headers,不能直接 install 目录名(会 EEXIST),
    # 改为安装各 Headers 的内容,合并到 include/webkit/。
    (include/"webkit").install Dir["build/JavaScriptCore/Headers/*"]
    (include/"webkit").install Dir["build/WTF/Headers/*"]
    (include/"webkit").install Dir["build/bmalloc/Headers/*"]
    # bun 构建时需要此文件验证 WebKit 配置完整性
    (include/"webkit").install "build/cmakeconfig.h" if File.exist?("build/cmakeconfig.h")
    # JSC 运行时头文件(Source + DerivedSources) — bun PCH 需要,
    # 以平面布局安装到 include/webkit/JavaScriptCore/(与 setup-webkit-cache.sh 一致)。
    jsc_inc = include/"webkit/JavaScriptCore"
    Dir.glob(buildpath.to_s + "/Source/JavaScriptCore/**/*.h").each do |h|
      cp h, jsc_inc/File.basename(h) unless File.exist?(jsc_inc/File.basename(h))
    end
    Dir.glob(buildpath.to_s + "/build/JavaScriptCore/DerivedSources/**/*.h").each do |h|
      cp h, jsc_inc/File.basename(h) unless File.exist?(jsc_inc/File.basename(h))
    end
  end

  def caveats
    <<~EOS
      bun-webkit provides JSC/WTF/bmalloc static archives for Bun on HarmonyOS.
      Pinned to WebKit commit 6d586e293f (matches bun's WEBKIT_VERSION).
      Consumed in-tree by the `bun` formula; keg-only.
    EOS
  end

  test do
    assert_predicate lib/"libJavaScriptCore.a", :exist?
    assert_predicate lib/"libWTF.a",            :exist?
    assert_predicate lib/"libbmalloc.a",         :exist?
  end
end
