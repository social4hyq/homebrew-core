class BunWebkit < Formula
  desc "JavaScriptCore/WTF/bmalloc static archives for Bun"
  homepage "https://github.com/oven-sh/bun"
  url "https://github.com/oven-sh/WebKit.git",
      revision: "6d586e293f008f0e74e5697611a379b1b24815c9"
  version "6d586e293f"
  license "BSD-3-Clause" # JavaScriptCore (JSCOnly port)
  # This formula is fully rewritten from upstream because it builds only the
  # JavaScriptCore/WTF/bmalloc static archives from oven-sh/WebKit, pinned to
  # bun's WEBKIT_VERSION. Upstream does not package WebKit this way.

  # WebKit source (oven-sh/WebKit official repo).
  # commit aligns with WEBKIT_VERSION in bun-src/scripts/build/deps/webkit.ts.
  # OHOS adaptation is handled by bun-side webkit.ts.patch, no need to modify WebKit source.

  # WebKit version must match WEBKIT_VERSION in bun-src/scripts/build/deps/webkit.ts,
  # cannot auto-bump, otherwise ABI mismatch with bun.
  livecheck do
    skip "pinned to bun's WEBKIT_VERSION"
  end

  bottle do
    root_url "https://github.com/social4hyq/homebrew-core/releases/download/bun-webkit-v6d586e293f"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a30b36850cb1af505384a22bfae7b4aae5706cc219392a3b05fcedb2609e3360"
  end

  keg_only "webKit static archives are consumed in-tree by Bun, not linked system-wide"

  depends_on "cmake"        => :build
  depends_on "gperf"        => :build
  depends_on "libxml2" => :build
  depends_on "ninja" => :build
  depends_on "perl" => :build
  depends_on "python@3.14" => :build
  depends_on "ruby" => :build
  depends_on "zlib" => :build
  # Outputs are static .a archives + headers — zero runtime linkage.
  depends_on "icu4c@78" => :build
  depends_on "llvm@21"  => :build
  depends_on "ohos-sdk" => :build # JSC cross-compilation uses its sysroot
  # llvm@21's lld runtime depends on libxml2/zlib; explicitly declare so superenv injects library paths.

  def install
    # llvm@21's lld runtime depends on libxml2/zlib, brew superenv may strip LD_LIBRARY_PATH,
    # explicitly inject library search paths (per icu4c@78 experience).
    ENV.prepend_path "LD_LIBRARY_PATH", Formula["libxml2"].opt_lib.to_s
    ENV.prepend_path "LD_LIBRARY_PATH", Formula["zlib"].opt_lib.to_s

    clang    = Formula["llvm@21"].opt_bin/"clang"
    clangxx  = Formula["llvm@21"].opt_bin/"clang++"
    sysroot  = "#{Formula["ohos-sdk"].opt_prefix}/native/sysroot"

    # OHOS cross-compilation flags (align with cfg.ohos branch in bun-src/scripts/build/deps/webkit.ts).
    target_flag = "--target=aarch64-linux-ohos"
    sysroot_flag = "--sysroot=#{sysroot}"
    icu_include = "-I#{Formula["icu4c@78"].opt_include}"

    cxxflags = [
      target_flag, sysroot_flag, "-D__MUSL__",
      "-mbranch-protection=none", "-mno-outline-atomics",
      "-nostdinc++ -I#{Formula["llvm@21"].opt_include}/aarch64-linux-ohos/c++/v1",
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

    # Output: libJavaScriptCore.a / libWTF.a / libbmalloc.a + headers
    # (cmake JSCOnly target output is in build/lib/)
    lib.install Dir["build/lib/libJavaScriptCore.a", "build/lib/libWTF.a", "build/lib/libbmalloc.a"]
    # All three components' top-level dirs are named Headers, cannot install dirs directly (EEXIST),
    # instead install the contents of each Headers, merged into include/webkit/.
    (include/"webkit").install Dir["build/JavaScriptCore/Headers/*"]
    (include/"webkit").install Dir["build/WTF/Headers/*"]
    (include/"webkit").install Dir["build/bmalloc/Headers/*"]
    # bun build needs this file to verify WebKit config completeness
    (include/"webkit").install "build/cmakeconfig.h" if File.exist?("build/cmakeconfig.h")
    # JSC runtime headers (Source + DerivedSources) — needed by bun PCH,
    # installed in flat layout under include/webkit/JavaScriptCore/ (consistent with setup-webkit-cache.sh).
    jsc_inc = include/"webkit/JavaScriptCore"
    # OHOS uses the socket-based remote inspector, not the glib one.
    # Exclude inspector/remote/glib/ so the basename-flatten picks the socket variant
    # of files that exist in both (notably RemoteInspectorServer.h).
    Dir.glob(buildpath.to_s + "/Source/JavaScriptCore/**/*.h").each do |h|
      next if h.include?("/inspector/remote/glib/")

      cp h, jsc_inc/File.basename(h) unless File.exist?(jsc_inc/File.basename(h))
    end
    Dir.glob(buildpath.to_s + "/build/JavaScriptCore/DerivedSources/**/*.h").each do |h|
      cp h, jsc_inc/File.basename(h) unless File.exist?(jsc_inc/File.basename(h))
    end
    # WTF platform subdirs (posix/cocoa/android/bun/…) are NOT in the cmake WTF/Headers
    # export but bun source pulls them in. Overlay from Source/WTF/wtf/ to match
    # setup-webkit-cache.sh. Skip glib/ (OHOS has no GLib).
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
      Pinned to WebKit commit 6d586e293f (matches bun's WEBKIT_VERSION).
      Consumed in-tree by the `bun` formula; keg-only.
    EOS
  end

  test do
    assert_path_exists lib/"libJavaScriptCore.a"
    assert_path_exists lib/"libWTF.a"
    assert_path_exists lib/"libbmalloc.a"
  end
end
