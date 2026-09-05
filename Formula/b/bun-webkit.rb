class BunWebkit < Formula
  desc "JavaScriptCore/WTF/bmalloc static archives for Bun"
  homepage "https://github.com/oven-sh/bun"
  url "https://github.com/oven-sh/WebKit.git",
      revision: "2e2aa2290fac856d6f451ceacb58f7f5b44dd057"
  version "2e2aa2290f"
  license "BSD-3-Clause" # JavaScriptCore (JSCOnly port)
  # Fully rewritten from upstream: builds only JSC/WTF/bmalloc static archives, pinned to bun's WEBKIT_VERSION.

  # Pinned to bun's WEBKIT_VERSION; OHOS adaptation handled bun-side (webkit.ts.patch).
  livecheck do
    skip "pinned to bun's WEBKIT_VERSION"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bun-webkit-v6119947592-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a59d48bef34061bc2f8907ca6a8ed1a9e38d91f509f3f94ccd24d9b63fdd2312"
  end

  keg_only "webkit static archives are consumed in-tree by Bun, not linked system-wide"

  depends_on "cmake"        => :build
  depends_on "gperf"        => :build
  depends_on "icu4c@78" => :build
  depends_on "libxml2" => :build
  depends_on "llvm@21"  => :build
  depends_on "ninja" => :build
  depends_on "ohos-sdk" => :build
  depends_on "perl" => :build
  depends_on "python@3.14" => :build
  depends_on "ruby" => :build
  depends_on "zlib" => :build
  # Outputs are static .a archives + headers — zero runtime linkage.
  # ohos-sdk is build-time only: JSC cross-compilation uses its sysroot.

  # Signal-driven thread suspend/resume (GC stack scan, libpas scavenger TLC flush)
  # deadlocks when the OHOS cgroup freezer swallows a handshake signal mid-sequence:
  # the suspender parks in sem_wait holding global locks (pas_heap_lock et al.) and the
  # whole process freezes. Drive the handshake with an atomic flag + bounded
  # sigtimedwait instead, so a lost/coalesced signal self-heals.
  patch :p1 do
    file "Patches/bun-webkit/0001-suspend-resume-handshake-survives-signal-loss.patch"
  end

  def install
    # llvm@21's lld runtime depends on libxml2/zlib; brew superenv may strip LD_LIBRARY_PATH, inject explicitly.
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("libxml2").to_s
    ENV.prepend_path "LD_LIBRARY_PATH", formula_opt_lib("zlib").to_s

    clang    = formula_opt_bin("llvm@21")/"clang"
    clangxx  = formula_opt_bin("llvm@21")/"clang++"
    sysroot  = "#{formula_opt_prefix("ohos-sdk")}/native/sysroot"

    # OHOS cross-compilation flags (align with cfg.ohos branch in bun-src/scripts/build/deps/webkit.ts).
    target_flag = "--target=aarch64-linux-ohos"
    sysroot_flag = "--sysroot=#{sysroot}"
    icu_include = "-I#{formula_opt_include("icu4c@78")}"

    cxxflags = [
      target_flag, sysroot_flag, "-D__MUSL__",
      "-mbranch-protection=none", "-mno-outline-atomics",
      "-nostdinc++ -I#{formula_opt_include("llvm@21")}/aarch64-linux-ohos/c++/v1",
      icu_include, "-fno-c++-static-destructors", "-std=gnu++23"
    ].join(" ")

    cflags = [
      target_flag, sysroot_flag, "-D__MUSL__",
      "-mbranch-protection=none", "-mno-outline-atomics", icu_include
    ].join(" ")

    mkdir buildpath/"build" do
      args = %W[
        -G Ninja
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=#{prefix}
        -DCMAKE_C_COMPILER=#{clang}
        -DCMAKE_CXX_COMPILER=#{clangxx}
        -DPORT=JSCOnly
        -DENABLE_STATIC_JSC=ON
        -DUSE_THIN_ARCHIVES=OFF
        -DENABLE_FTL_JIT=ON
        -DUSE_BUN_JSC_ADDITIONS=ON
        -DUSE_BUN_EVENT_LOOP=ON
        -DUSE_MIMALLOC=ON
        -DUSE_EXTERNAL_MIMALLOC=ON
        -DENABLE_BUN_SKIP_FAILING_ASSERTIONS=ON
        -DALLOW_LINE_AND_COLUMN_NUMBER_IN_BUILTINS=ON
        -DENABLE_REMOTE_INSPECTOR=ON
        -DENABLE_MEDIA_SOURCE=OFF
        -DENABLE_MEDIA_STREAM=OFF
        -DENABLE_WEB_RTC=OFF
        -DENABLE_SWIFT_DEMO_URI_SCHEME=OFF
        -DENABLE_BACK_FORWARD_LIST_SWIFT=OFF
        -DCMAKE_SYSTEM_NAME=Linux
        -DCMAKE_SYSTEM_PROCESSOR=aarch64
        -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY
        -DCMAKE_FIND_ROOT_PATH=#{sysroot};#{formula_opt_prefix("icu4c@78")}
        -DCMAKE_PREFIX_PATH=#{formula_opt_prefix("icu4c@78")}
        -DICU_ROOT=#{formula_opt_prefix("icu4c@78")}
        -DICU_INCLUDE_DIR=#{formula_opt_include("icu4c@78")}
        -DCMAKE_HAVE_THREADS_LIBRARY=1
      ]
      # Multi-word flags must not go in %W[...] — %W splits on whitespace, and
      # cmake 4 hard-errors on the resulting bare fragments ("Unknown argument"
      # / unknown -W category). Append them as single argv elements instead.
      args << "-DCMAKE_C_FLAGS=#{cflags}"
      args << "-DCMAKE_CXX_FLAGS=#{cxxflags}"
      args << "-DCMAKE_EXE_LINKER_FLAGS=-L#{formula_opt_lib("llvm@21")}/aarch64-linux-ohos -Wl,--code-sign"
      system "cmake", *args, buildpath.to_s
      system "ninja", "-j", ENV.make_jobs.to_s, "JavaScriptCore", "WTF", "bmalloc"
    end

    # Output: libJavaScriptCore.a / libWTF.a / libbmalloc.a + headers
    # (cmake JSCOnly target output is in build/lib/)
    lib.install Dir["build/lib/libJavaScriptCore.a", "build/lib/libWTF.a", "build/lib/libbmalloc.a"]
    # All three components' top-level dirs are named Headers; install contents merged
    # into include/webkit/.
    (include/"webkit").install Dir["build/JavaScriptCore/Headers/*"]
    (include/"webkit").install Dir["build/WTF/Headers/*"]
    (include/"webkit").install Dir["build/bmalloc/Headers/*"]
    # bun build needs cmakeconfig.h for config verification
    (include/"webkit").install "build/cmakeconfig.h" if File.exist?("build/cmakeconfig.h")
    # JSC runtime headers (Source + DerivedSources), flattened under include/webkit/JavaScriptCore/.
    jsc_inc = include/"webkit/JavaScriptCore"
    # Exclude inspector/remote/glib/ (OHOS uses socket-based inspector).
    Dir.glob(buildpath.to_s + "/Source/JavaScriptCore/**/*.h").each do |h|
      next if h.include?("/inspector/remote/glib/")

      cp h, jsc_inc/File.basename(h) unless File.exist?(jsc_inc/File.basename(h))
    end
    Dir.glob(buildpath.to_s + "/build/JavaScriptCore/DerivedSources/**/*.h").each do |h|
      cp h, jsc_inc/File.basename(h) unless File.exist?(jsc_inc/File.basename(h))
    end
    # WTF platform subdirs not in cmake export but bun needs them.
    # Overlay from Source/WTF/wtf/; skip glib/.
    wtf_inc = include/"webkit/wtf"
    Dir.glob(buildpath.to_s + "/Source/WTF/wtf/*").each do |entry|
      next unless File.directory?(entry)

      name = File.basename(entry)
      next if name == "glib"

      dest = wtf_inc/name
      cp_r entry, dest unless dest.exist?
    end
    Dir.glob(buildpath.to_s + "/Source/WTF/wtf/*.h").each do |h|
      cp h, wtf_inc/File.basename(h) unless File.exist?(wtf_inc/File.basename(h))
    end
  end

  def caveats
    <<~EOS
      bun-webkit provides JSC/WTF/bmalloc static archives for Bun on HarmonyOS.
      Pinned to WebKit commit #{version} (matches bun's WEBKIT_VERSION).
      Consumed in-tree by the `bun` formula; keg-only.
    EOS
  end

  test do
    assert_path_exists lib/"libJavaScriptCore.a"
    assert_path_exists lib/"libWTF.a"
    assert_path_exists lib/"libbmalloc.a"
  end
end
