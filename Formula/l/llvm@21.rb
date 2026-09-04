class LlvmAT21 < Formula
  desc "Next-gen compiler infrastructure"
  homepage "https://llvm.org/"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-21.1.8/llvm-project-21.1.8.src.tar.xz"
  sha256 "4633a23617fa31a3ea51242586ea7fb1da7140e426bd62fc164261fe036aa142"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0" => { with: "LLVM-exception" }
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^llvmorg[._-]v?(21(?:\.\d+)+)$/i)
  end

  keg_only :versioned_formula

  # https://llvm.org/docs/GettingStarted.html#requirement
  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "python@3.14" => [:build, :test]
  depends_on "zstd"

  uses_from_macos "libedit"
  uses_from_macos "libffi"

  on_linux do
    depends_on "pkgconf" => :build
    depends_on "ohos-sdk" # sysroot + libcxx-ohos headers; see DEFAULT_SYSROOT below
    depends_on "zlib-ng-compat"
  end

  # Fix triple config loading for clang-cl
  patch do
    url "https://github.com/llvm/llvm-project/compare/1381ad497b9a6d3da630cbef53cbfa9ddf117bb6...40a8c7c0ff3f688b690e4c74db734de67f0f89e9.diff"
    sha256 "f6dafd762737eb79761ab7ef814a9fc802ec4bb8d20f46691f07178053b0eb36"
    type :unofficial
    resolves "https://github.com/llvm/llvm-project/pull/111397"
  end

  # OHOS: `uname -s` reports "HarmonyOS", which llvm/cmake/config.guess doesn't
  # recognize. GetHostTriple.cmake calls this script unconditionally to infer
  # LLVM_HOST_TRIPLE and treats a non-zero exit as a fatal configure error.
  patch do
    file "Patches/llvm@21/0001-config-guess-harmonyos.patch"
  end

  # cmake 4.x's if() parser rejects the extra parens this file wraps its
  # conditions in (CMake bug unrelated to platform, not OHOS-specific).
  patch do
    file "Patches/llvm@21/0002-cmake4-if-parser-compat.patch"
  end

  # TARGET_TRIPLE is what downstream projects pass as `--target=` when
  # cross-building for OHOS on this same (aarch64) hardware; it differs from
  # the host triple below because OHOS's clang driver always normalizes to
  # this shorter form for resource-dir / runtime-library lookups (see
  # clang/lib/Driver/ToolChains/OHOS.cpp getMultiarchTriple()).
  TARGET_TRIPLE = "aarch64-linux-ohos".freeze
  # For test assertions only; not passed to cmake — the config.guess patch
  # above makes LLVM infer this on its own.
  HOST_TRIPLE = "aarch64-unknown-linux-ohos".freeze

  def python3
    "python3.14"
  end

  def clang_config_file_dir
    etc/"clang"
  end

  def install
    # The clang bindings need a little help finding our libclang.
    inreplace "clang/bindings/python/clang/cindex.py",
              /^(\s*library_path\s*=\s*)None$/,
              "\\1'#{lib}'"

    projects = %w[
      clang
      clang-tools-extra
      mlir
      polly
    ]
    # compiler-rt is deliberately absent here: OHOS's clang driver looks for
    # it at lib/clang/<ver>/lib/aarch64-linux-ohos/ (no arch-triple subdir the
    # way a normal host build produces), so a host-triple compiler-rt build
    # would just sit unused. build_ohos_target_runtimes below builds and
    # installs it at the path the driver actually searches.
    runtimes = %w[
      libcxx
      libcxxabi
      libunwind
    ]

    python_versions = Formula.names
                             .select { |name| name.start_with? "python@" }
                             .map { |py| py.delete_prefix("python@") }

    # compiler-rt has some iOS simulator features that require i386 symbols
    # I'm assuming the rest of clang needs support too for 32-bit compilation
    # to work correctly, but if not, perhaps universal binaries could be
    # limited to compiler-rt. llvm makes this somewhat easier because compiler-rt
    # can almost be treated as an entirely different build from llvm.
    ENV.permit_arch_flags

    # OHOS is musl-based; upstream's `ENV.cflags` forwarding a few lines down
    # (into args / runtimes_cmake_args / builtins_cmake_args) picks this up.
    ENV.append_to_cflags "-D__MUSL__"

    ohos_sdk    = formula_opt_prefix("ohos-sdk")
    sysroot     = "#{ohos_sdk}/native/sysroot"
    libcxx_ohos = "#{ohos_sdk}/native/llvm/include/libcxx-ohos/include/c++/v1"
    odie "OHOS sysroot missing: #{sysroot}/usr/lib" unless File.directory?("#{sysroot}/usr/lib")
    odie "libcxx-ohos headers missing: #{libcxx_ohos}" unless File.directory?(libcxx_ohos)

    # cmake has no Platform/HarmonyOS.cmake (CMAKE_SYSTEM_NAME defaults to
    # `uname -s` for a native build); without it, shared libs lose SONAME,
    # RUNPATH/RPATH flags, -Bstatic/-Bdynamic and --start-group/--end-group.
    # `-DCMAKE_SYSTEM_NAME=Linux` isn't a substitute: setting it explicitly
    # would make cmake think this is a cross-compile (CMAKE_CROSSCOMPILING=TRUE)
    # and drag LLVM into its (much more expensive) cross-build path.
    cmake_modules = buildpath/"cmake-modules"
    (cmake_modules/"Platform").mkpath
    (cmake_modules/"Platform/HarmonyOS.cmake").write "include(Platform/Linux)\n"

    args = %W[
      -DLLVM_ENABLE_PROJECTS=#{projects.join(";")}
      -DLLVM_ENABLE_RUNTIMES=#{runtimes.join(";")}
      -DLLVM_POLLY_LINK_INTO_TOOLS=ON
      -DLLVM_BUILD_EXTERNAL_COMPILER_RT=ON
      -DLLVM_LINK_LLVM_DYLIB=ON
      -DLLVM_ENABLE_EH=OFF
      -DLLVM_ENABLE_FFI=ON
      -DLLVM_ENABLE_RTTI=ON
      -DLLVM_INCLUDE_DOCS=OFF
      -DLLVM_INCLUDE_TESTS=OFF
      -DLLVM_INSTALL_UTILS=ON
      -DLLVM_ENABLE_Z3_SOLVER=OFF
      -DLLVM_OPTIMIZED_TABLEGEN=ON
      -DLLVM_TARGETS_TO_BUILD=all
      -DLLVM_USE_RELATIVE_PATHS_IN_FILES=ON
      -DLLVM_SOURCE_PREFIX=.
      -DLIBCXX_INSTALL_MODULES=ON
      -DCLANG_PYTHON_BINDINGS_VERSIONS=#{python_versions.join(";")}
      -DLLVM_CREATE_XCODE_TOOLCHAIN=OFF
      -DCLANG_FORCE_MATCHING_LIBCLANG_SOVERSION=OFF
      -DCLANG_CONFIG_FILE_SYSTEM_DIR=#{clang_config_file_dir.relative_path_from(bin)}
      -DCLANG_CONFIG_FILE_USER_DIR=~/.config/clang
      -DCMAKE_MODULE_PATH=#{cmake_modules}
    ]

    if tap.present?
      args += %W[
        -DPACKAGE_VENDOR=#{tap.user}
        -DBUG_REPORT_URL=#{tap.issues_url}
      ]
      args << "-DCLANG_VENDOR_UTI=sh.brew.clang" if tap.official?
    end

    runtimes_cmake_args = ["-DCMAKE_MODULE_PATH=#{cmake_modules}"]
    builtins_cmake_args = []

    if OS.mac?
      macos_sdk = MacOS.sdk_path
      args << "-DFFI_INCLUDE_DIR=#{macos_sdk}/usr/include/ffi"
      args << "-DFFI_LIBRARY_DIR=#{macos_sdk}/usr/lib"

      libcxx_install_libdir = lib/"c++"
      libunwind_install_libdir = lib/"unwind"
      libcxx_rpaths = [loader_path, rpath(source: libcxx_install_libdir, target: libunwind_install_libdir)]

      args << "-DLLVM_BUILD_LLVM_C_DYLIB=ON"
      args << "-DLLVM_ENABLE_LIBCXX=ON"
      args << "-DLIBCXX_ENABLE_VENDOR_AVAILABILITY_ANNOTATIONS=ON"
      args << "-DLIBCXX_PSTL_BACKEND=libdispatch"
      args << "-DLIBCXX_INSTALL_LIBRARY_DIR=#{libcxx_install_libdir}"
      args << "-DLIBUNWIND_INSTALL_LIBRARY_DIR=#{libunwind_install_libdir}"
      args << "-DLIBCXXABI_INSTALL_LIBRARY_DIR=#{libcxx_install_libdir}"
      runtimes_cmake_args << "-DCMAKE_INSTALL_RPATH=#{libcxx_rpaths.join("|")}"

      # Disable builds for OSes not supported by the CLT SDK.
      clt_sdk_support_flags = %w[I WATCH TV].map { |os| "-DCOMPILER_RT_ENABLE_#{os}OS=OFF" }
      builtins_cmake_args += clt_sdk_support_flags
    else
      args << "-DFFI_INCLUDE_DIR=#{formula_opt_include("libffi")}"
      args << "-DFFI_LIBRARY_DIR=#{formula_opt_lib("libffi")}"

      # Disable `libxml2` which isn't very useful.
      args << "-DLLVM_ENABLE_LIBXML2=OFF"
      # OHOS has no usable system libstdc++ (musl); libc++ is the only option.
      args << "-DLLVM_ENABLE_LIBCXX=ON"
      args << "-DCLANG_DEFAULT_CXX_STDLIB=libc++"
      args << "-DCLANG_DEFAULT_RTLIB=compiler-rt"
      args << "-DCLANG_DEFAULT_UNWINDLIB=libunwind"
      # Not `-DCLANG_DEFAULT_LINKER=lld`: lld is a separate, optional formula
      # (lld@21) here. OHOS's driver already defaults to lld; leaving this
      # unset lets it fall back to whatever `ld.lld` is on PATH (ohos-sdk's,
      # if lld@21 isn't installed) instead of hard-failing.
      args << "-DDEFAULT_SYSROOT=#{sysroot}"
      # Parts of Polly fail to correctly build with PIC when being used for DSOs.
      args << "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
      runtimes_cmake_args += %w[
        -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON

        -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON
        -DLIBCXX_STATICALLY_LINK_ABI_IN_SHARED_LIBRARY=OFF
        -DLIBCXX_STATICALLY_LINK_ABI_IN_STATIC_LIBRARY=ON
        -DLIBCXX_USE_COMPILER_RT=ON
        -DLIBCXX_HAS_ATOMIC_LIB=OFF

        -DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON
        -DLIBCXXABI_STATICALLY_LINK_UNWINDER_IN_SHARED_LIBRARY=OFF
        -DLIBCXXABI_STATICALLY_LINK_UNWINDER_IN_STATIC_LIBRARY=ON
        -DLIBCXXABI_USE_COMPILER_RT=ON
        -DLIBCXXABI_USE_LLVM_UNWINDER=ON

        -DLIBUNWIND_USE_COMPILER_RT=ON
        -DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON
        -DCOMPILER_RT_USE_LLVM_UNWINDER=ON
      ]
      runtimes_cmake_args += %w[
        -DLIBCXX_HAS_MUSL_LIBC=ON
        -DLIBCXX_HAS_PTHREAD_API=ON
        -DLIBCXX_ABI_NAMESPACE=__n1
      ]
      # __n1 is the only ABI namespace OHOS sanctions for third-party
      # distribution. The OHOS target-side runtimes built below must match
      # (a stale/default __1 won't link against these host libc++ headers).

      # Prevent compiler-rt from building i386 targets, as this is not portable.
      builtins_cmake_args << "-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON"
    end

    if ENV.cflags.present?
      args << "-DCMAKE_C_FLAGS=#{ENV.cflags}"
      runtimes_cmake_args << "-DCMAKE_C_FLAGS=#{ENV.cflags}"
      builtins_cmake_args << "-DCMAKE_C_FLAGS=#{ENV.cflags}"
    end

    if ENV.cxxflags.present?
      args << "-DCMAKE_CXX_FLAGS=#{ENV.cxxflags}"
      runtimes_cmake_args << "-DCMAKE_CXX_FLAGS=#{ENV.cxxflags}"
      builtins_cmake_args << "-DCMAKE_CXX_FLAGS=#{ENV.cxxflags}"
    end

    args << "-DRUNTIMES_CMAKE_ARGS=#{runtimes_cmake_args.join(";")}" if runtimes_cmake_args.present?
    args << "-DBUILTINS_CMAKE_ARGS=#{builtins_cmake_args.join(";")}" if builtins_cmake_args.present?

    # The clang-shlib LINKER:--version-script fix the old rewrite carried is
    # not needed here: that codepath is gated by
    # `CMAKE_SYSTEM_NAME STREQUAL "Linux"`, and CMAKE_SYSTEM_NAME on a native
    # OHOS build is "HarmonyOS" (Platform/HarmonyOS.cmake only borrows Linux's
    # *settings* via include(), it doesn't change CMAKE_SYSTEM_NAME itself) —
    # so that branch never executes and never needed patching.
    llvmpath = buildpath/"llvm"

    mkdir llvmpath/"build" do
      system "cmake", "-G", "Ninja", "..", *(std_cmake_args + args)
      system "cmake", "--build", "."
      system "cmake", "--build", ".", "--target", "install"
    end

    # OHOS: the driver only looks for compiler-rt / libc++ / libunwind under
    # this exact target-triple directory (see TARGET_TRIPLE comment above).
    # No upstream equivalent — the host build above is self-hosting only.
    build_ohos_target_runtimes(sysroot: sysroot, libcxx_ohos: libcxx_ohos)

    # Install Vim plugins
    %w[ftdetect ftplugin indent syntax].each do |dir|
      (share/"vim/vimfiles"/dir).install Pathname.glob("*/utils/vim/#{dir}/*.vim")
    end

    # Install Emacs modes
    elisp.install llvmpath.glob("utils/emacs/*.el") + share.glob("clang/*.el")

    # TODO: switch to `post_install_steps do configure_clang_system end` (the
    # macOS Info.plist/xctoolchain install + per-macOS-version clang config
    # file generation upstream does here) once the local brew fork catches up
    # with upstream Homebrew — `post_install_steps` and `Utils::Clang` don't
    # exist yet in this fork. Not relevant on OHOS regardless (macOS-only).
  end

  def build_ohos_target_runtimes(sysroot:, libcxx_ohos:)
    jobs     = ENV.make_jobs
    cc       = bin/"clang"
    cxx      = bin/"clang++"
    llvm_ar  = bin/"llvm-ar"
    ranlib   = bin/"llvm-ranlib"
    runtimes = buildpath/"runtimes"

    # Both cc/cxx below are invoked by absolute path (the freshly built
    # keg's own clang), bypassing superenv's `cc` shim — which is what
    # injects -fno-emulated-tls (native TLS is ~30% faster than clang's
    # default emulated-TLS codegen for OHOS targets) for every other
    # compiler invocation in this formula. Set it explicitly here.
    cflags = "--target=#{TARGET_TRIPLE} --sysroot=#{sysroot} -D__MUSL__ -fPIC -fno-emulated-tls"

    build_target_compiler_rt(cc:, cxx:, llvm_ar:, ranlib:, runtimes:, cflags:, jobs:)
    build_target_multiarch_libcxx(cc:, cxx:, llvm_ar:, ranlib:, runtimes:, cflags:, sysroot:, libcxx_ohos:, jobs:)
  end

  def build_target_compiler_rt(cc:, cxx:, llvm_ar:, ranlib:, runtimes:, cflags:, jobs:)
    rt_root = Pathname.glob("#{lib}/clang/*").first
    odie "compiler-rt host dir missing: #{lib}/clang/<ver>" unless rt_root
    rt_tgt = rt_root/"lib"/TARGET_TRIPLE
    rt_tgt.mkpath

    mkdir buildpath/"compiler-rt-build" do
      system "cmake", "-G", "Ninja",
             "-DCMAKE_SYSTEM_NAME=Linux",
             "-DCMAKE_SYSTEM_PROCESSOR=aarch64",
             "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY",
             "-DCMAKE_C_COMPILER=#{cc}",
             "-DCMAKE_CXX_COMPILER=#{cxx}",
             "-DCMAKE_ASM_COMPILER=#{cc}",
             "-DCMAKE_C_COMPILER_TARGET=#{TARGET_TRIPLE}",
             "-DCMAKE_CXX_COMPILER_TARGET=#{TARGET_TRIPLE}",
             "-DCMAKE_ASM_COMPILER_TARGET=#{TARGET_TRIPLE}",
             "-DCMAKE_AR=#{llvm_ar}",
             "-DCMAKE_RANLIB=#{ranlib}",
             "-DCMAKE_C_FLAGS=#{cflags}",
             "-DCMAKE_CXX_FLAGS=#{cflags}",
             "-DCMAKE_ASM_FLAGS=#{cflags}",
             "-DLLVM_ENABLE_RUNTIMES=compiler-rt",
             "-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON",
             "-DCOMPILER_RT_BUILD_BUILTINS=ON",
             "-DCOMPILER_RT_BUILD_CRT=ON",
             "-DCOMPILER_RT_BUILD_SANITIZERS=OFF",
             "-DCOMPILER_RT_BUILD_LIBFUZZER=OFF",
             "-DCOMPILER_RT_BUILD_PROFILE=OFF",
             "-DCOMPILER_RT_BUILD_MEMPROF=OFF",
             "-DCOMPILER_RT_BUILD_XRAY=OFF",
             "-DCOMPILER_RT_BUILD_ORC=OFF",
             "-DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON",
             "-DCOMPILER_RT_USE_LLVM_UNWINDER=ON",
             "-DCOMPILER_RT_ENABLE_STATIC_UNWINDER=ON",
             runtimes.to_s
      system "ninja", "-j", jobs.to_s, "builtins", "crt"
    end

    Pathname.glob("#{buildpath}/compiler-rt-build/**/*").each do |f|
      next unless f.file?

      base = case f.basename.to_s
      when /\Alibclang_rt\.builtins-.*\.a\z/ then "libclang_rt.builtins.a"
      when /\Aclang_rt\.crtbegin-.*\.o\z/    then "clang_rt.crtbegin.o"
      when /\Aclang_rt\.crtend-.*\.o\z/      then "clang_rt.crtend.o"
      else next
      end
      cp(f, rt_tgt/base)
    end

    odie "libclang_rt.builtins.a missing in #{rt_tgt}" unless (rt_tgt/"libclang_rt.builtins.a").exist?
  end

  def build_target_multiarch_libcxx(cc:, cxx:, llvm_ar:, ranlib:, runtimes:, cflags:, sysroot:, libcxx_ohos:, jobs:)
    libcxxabi_inc = buildpath/"libcxxabi/include"
    cxxflags_unwind = "#{cflags} -I#{sysroot}/usr/include -I#{libcxxabi_inc} -I#{libcxx_ohos} -nostdinc++"
    cflags_full = "#{cflags} -I#{sysroot}/usr/include -funwind-tables -fno-omit-frame-pointer"

    cmake_runtime = %W[
      -DCMAKE_SYSTEM_NAME=Linux
      -DCMAKE_SYSTEM_PROCESSOR=aarch64
      -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY
      -DCMAKE_REQUIRED_FLAGS=--target=#{TARGET_TRIPLE};--sysroot=#{sysroot}
    ]

    stage = buildpath/"multiarch-runtimes-stage"
    (stage/"libunwind").mkpath
    (stage/"libcxx").mkpath

    mkdir buildpath/"multiarch-libunwind" do
      system "cmake", "-G", "Ninja",
             *cmake_runtime,
             "-DCMAKE_C_COMPILER=#{cc}",
             "-DCMAKE_CXX_COMPILER=#{cxx}",
             "-DCMAKE_ASM_COMPILER=#{cc}",
             "-DCMAKE_AR=#{llvm_ar}",
             "-DCMAKE_RANLIB=#{ranlib}",
             "-DCMAKE_C_FLAGS=#{cflags_full}",
             "-DCMAKE_CXX_FLAGS=#{cxxflags_unwind}",
             "-DCMAKE_ASM_FLAGS=#{cflags_full}",
             "-DCMAKE_INSTALL_PREFIX=#{stage}/libunwind",
             "-DLLVM_ENABLE_RUNTIMES=libunwind",
             "-DLIBUNWIND_ENABLE_SHARED=OFF",
             "-DLIBUNWIND_USE_COMPILER_RT=ON",
             "-DLIBUNWIND_ENABLE_THREADS=ON",
             runtimes.to_s
      system "ninja", "-j", jobs.to_s, "install"
    end

    mkdir buildpath/"multiarch-libcxx" do
      system "cmake", "-G", "Ninja",
             *cmake_runtime,
             "-DCMAKE_C_COMPILER=#{cc}",
             "-DCMAKE_CXX_COMPILER=#{cxx}",
             "-DCMAKE_ASM_COMPILER=#{cc}",
             "-DCMAKE_AR=#{llvm_ar}",
             "-DCMAKE_RANLIB=#{ranlib}",
             "-DCMAKE_C_FLAGS=#{cflags_full}",
             "-DCMAKE_CXX_FLAGS=#{cflags_full}",
             "-DCMAKE_INSTALL_PREFIX=#{stage}/libcxx",
             "-DLLVM_ENABLE_RUNTIMES=libunwind;libcxxabi;libcxx",
             "-DLIBCXX_ENABLE_SHARED=OFF",
             "-DLIBUNWIND_ENABLE_SHARED=OFF",
             "-DLIBUNWIND_USE_COMPILER_RT=ON",
             "-DLIBCXXABI_ENABLE_SHARED=OFF",
             "-DLIBCXXABI_USE_COMPILER_RT=ON",
             "-DLIBCXXABI_USE_LLVM_UNWINDER=ON",
             "-DLIBCXX_CXX_ABI=libcxxabi",
             "-DLIBCXX_ABI_NAMESPACE=__n1",
             "-DLIBCXX_HAS_MUSL_LIBC=ON",
             "-DLIBCXX_HAS_PTHREAD_API=ON",
             "-DLIBCXX_CXX_ABI_INCLUDE_PATHS=#{libcxxabi_inc}",
             "-DLIBCXX_USE_COMPILER_RT=ON",
             "-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON",
             "-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON",
             "-DLIBCXXABI_STATICALLY_LINK_UNWINDER_IN_STATIC_LIBRARY=OFF",
             "-DLIBCXXABI_HAS_CXA_THREAD_ATEXIT_IMPL=OFF",
             runtimes.to_s
      system "ninja", "-j", jobs.to_s, "install"
    end

    target_libdir = lib/TARGET_TRIPLE
    target_incdir = include/TARGET_TRIPLE/"c++/v1"
    target_libdir.mkpath
    target_incdir.dirname.mkpath

    mv("#{stage}/libcxx/lib/libc++.a",             target_libdir/"libc++_static.a")
    mv("#{stage}/libcxx/lib/libc++abi.a",          target_libdir/"libc++abi.a")
    mv("#{stage}/libcxx/lib/libc++experimental.a", target_libdir/"libc++experimental.a")
    modules_json = stage/"libcxx/lib/libc++.modules.json"
    mv(modules_json, target_libdir/"libc++.modules.json") if modules_json.exist?
    mv("#{stage}/libunwind/lib/libunwind.a", target_libdir/"libunwind.a")
    rm_r(target_incdir) if target_incdir.exist?
    mv("#{stage}/libcxx/include/c++/v1", target_incdir)

    (target_libdir/"libc++.a").write <<~LDSCRIPT
      INPUT(-lc++_static -lc++abi -lunwind)
    LDSCRIPT

    odie "target libc++ missing" unless (target_libdir/"libc++_static.a").exist?
  end

  def caveats
    s = <<~EOS
      CLANG_CONFIG_FILE_SYSTEM_DIR: #{clang_config_file_dir}
      CLANG_CONFIG_FILE_USER_DIR:   ~/.config/clang

      LLD is now provided in a separate formula:
        brew install lld@21

      OHOS-specific:
        Default sysroot:            #{HOMEBREW_PREFIX}/opt/ohos-sdk/native/sysroot
        Host triple:                #{HOST_TRIPLE}
        Target-triple runtime libs: #{TARGET_TRIPLE} (compiler-rt/libc++/libunwind
          statically linked into anything built with `--target=#{TARGET_TRIPLE}`)
        libc++ ABI namespace is __n1 (OHOS's mandated third-party namespace) on
          both host and target-triple builds — link against a matching one.

      Example:
        #{opt_bin}/clang++ -stdlib=libc++ --target=#{TARGET_TRIPLE} \\
          --sysroot=#{HOMEBREW_PREFIX}/opt/ohos-sdk/native/sysroot \\
          hello.cpp -o hello
    EOS

    on_macos do
      s += <<~EOS

        Using `clang`, `clang++`, etc., requires a CLT installation at `/Library/Developer/CommandLineTools`.
        If you don't want to install the CLT, you can write appropriate configuration files pointing to your
        SDK at ~/.config/clang.

        To use the bundled libunwind please use the following LDFLAGS:
          LDFLAGS="-L#{opt_lib}/unwind -lunwind"

        To use the bundled libc++ please use the following LDFLAGS:
          LDFLAGS="-L#{opt_lib}/c++ -L#{opt_lib}/unwind -lunwind"
        Features newer than system libc++ will require the following define to enable:
          CPPFLAGS="-D_LIBCPP_DISABLE_AVAILABILITY"

        NOTE: You probably want to use the libunwind and libc++ provided by macOS unless you know what you're doing.
      EOS
    end

    s
  end

  test do
    alt_location_libs = [
      shared_library("libc++", "*"),
      shared_library("libc++abi", "*"),
      shared_library("libunwind", "*"),
    ]
    assert_empty lib.glob(alt_location_libs) if OS.mac?

    llvm_version = Utils.safe_popen_read(bin/"llvm-config", "--version").strip
    llvm_version_major = Version.new(llvm_version).major.to_s
    soversion = llvm_version_major.dup
    assert_equal version, llvm_version

    assert_equal prefix.to_s, shell_output("#{bin}/llvm-config --prefix").chomp
    assert_equal "-lLLVM-#{soversion}", shell_output("#{bin}/llvm-config --libs").chomp
    assert_equal (lib/shared_library("libLLVM-#{soversion}")).to_s,
                 shell_output("#{bin}/llvm-config --libfiles").chomp

    # OHOS: confirms the config.guess patch actually made LLVM infer the
    # right host triple (this is the load-bearing regression test for it).
    assert_match HOST_TRIPLE, shell_output("#{bin}/clang --version") if OS.linux?

    (testpath/"test.c").write <<~C
      #include <stdio.h>
      int main()
      {
        printf("Hello World!\\n");
        return 0;
      }
    C

    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      #include <string>
      int main()
      {
        std::string str = "Hello World!";
        std::size_t str_hash = std::hash<std::string>{}(str);
        std::cout << str << std::endl;
        return 0;
      }
    CPP

    system bin/"clang-cpp", "-v", "test.c"
    system bin/"clang-cpp", "-v", "test.cpp"

    # Testing default toolchain and SDK location.
    system bin/"clang++", "-v",
           "-std=c++11", "test.cpp", "-o", "test++"
    assert_includes MachO::Tools.dylibs("test++"), "/usr/lib/libc++.1.dylib" if OS.mac?
    assert_equal "Hello World!", shell_output("./test++").chomp
    system bin/"clang", "-v", "test.c", "-o", "test"
    assert_equal "Hello World!", shell_output("./test").chomp

    # These tests should ignore the usual SDK includes
    with_env(CPATH: nil) do
      # Testing Command Line Tools
      if OS.mac? && MacOS::CLT.installed?
        toolchain_path = "/Library/Developer/CommandLineTools"
        cpp_base = (MacOS.version >= :big_sur) ? MacOS::CLT.sdk_path : toolchain_path
        system bin/"clang++", "-v",
               "--no-default-config",
               "-isysroot", MacOS::CLT.sdk_path,
               "-isystem", "#{cpp_base}/usr/include/c++/v1",
               "-isystem", "#{MacOS::CLT.sdk_path}/usr/include",
               "-isystem", "#{toolchain_path}/usr/include",
               "-std=c++11", "test.cpp", "-o", "testCLT++"
        assert_includes MachO::Tools.dylibs("testCLT++"), "/usr/lib/libc++.1.dylib"
        assert_equal "Hello World!", shell_output("./testCLT++").chomp
        system bin/"clang", "-v", "test.c", "-o", "testCLT"
        assert_equal "Hello World!", shell_output("./testCLT").chomp

        targets = ["#{Hardware::CPU.arch}-apple-macosx#{MacOS.full_version}"]

        # The test tends to time out on Intel, so let's do these only for ARM macOS.
        if Hardware::CPU.arm?
          old_macos_version = HOMEBREW_MACOS_OLDEST_SUPPORTED.to_i - 1
          targets << "#{Hardware::CPU.arch}-apple-macosx#{old_macos_version}"

          old_kernel_version = MacOSVersion.kernel_major_version(MacOSVersion.new(old_macos_version.to_s))
          targets << "#{Hardware::CPU.arch}-apple-darwin#{old_kernel_version}"
        end

        targets.each do |target|
          system bin/"clang-cpp", "-v", "--target=#{target}", "test.c"
          system bin/"clang-cpp", "-v", "--target=#{target}", "test.cpp"

          system bin/"clang", "-v", "--target=#{target}", "test.c", "-o", "test-macosx"
          assert_equal "Hello World!", shell_output("./test-macosx").chomp

          system bin/"clang++", "-v", "--target=#{target}", "-std=c++11", "test.cpp", "-o", "test++-macosx"
          assert_equal "Hello World!", shell_output("./test++-macosx").chomp
        end
      end

      # Testing Xcode
      if OS.mac? && MacOS::Xcode.installed?
        cpp_base = (MacOS::Xcode.version >= "12.5") ? MacOS::Xcode.sdk_path : MacOS::Xcode.toolchain_path
        system bin/"clang++", "-v",
               "--no-default-config",
               "-isysroot", MacOS::Xcode.sdk_path,
               "-isystem", "#{cpp_base}/usr/include/c++/v1",
               "-isystem", "#{MacOS::Xcode.sdk_path}/usr/include",
               "-isystem", "#{MacOS::Xcode.toolchain_path}/usr/include",
               "-std=c++11", "test.cpp", "-o", "testXC++"
        assert_includes MachO::Tools.dylibs("testXC++"), "/usr/lib/libc++.1.dylib"
        assert_equal "Hello World!", shell_output("./testXC++").chomp
        system bin/"clang", "-v",
               "-isysroot", MacOS.sdk_path,
               "test.c", "-o", "testXC"
        assert_equal "Hello World!", shell_output("./testXC").chomp
      end

      # link against installed libc++
      # related to https://github.com/Homebrew/legacy-homebrew/issues/47149
      cxx_libdir = OS.mac? ? opt_lib/"c++" : opt_lib
      system bin/"clang++", "-v",
             "-isystem", "#{opt_include}/c++/v1",
             "-std=c++11", "-stdlib=libc++", "test.cpp", "-o", "testlibc++",
             "-rtlib=compiler-rt", "-L#{cxx_libdir}", "-Wl,-rpath,#{cxx_libdir}"
      assert_includes (testpath/"testlibc++").dynamically_linked_libraries,
                      (cxx_libdir/shared_library("libc++", "1")).to_s
      (testpath/"testlibc++").dynamically_linked_libraries.each do |lib|
        refute_match(/libstdc\+\+/, lib)
        refute_match(/libgcc/, lib)
        refute_match(/libatomic/, lib)
      end
      assert_equal "Hello World!", shell_output("./testlibc++").chomp
    end

    if OS.linux?
      # Link installed libc++, libc++abi, and libunwind archives both into
      # a position independent executable (PIE), as well as into a fully
      # position independent (PIC) DSO for things like plugins that export
      # a C-only API but internally use C++.
      #
      # FIXME: It'd be nice to be able to use flags like `-static-libstdc++`
      # together with `-stdlib=libc++` (the latter one we need anyways for
      # headers) to achieve this but those flags don't set up the correct
      # search paths or handle all of the libraries needed by `libc++` when
      # linking statically.

      system bin/"clang++", "-v", "-o", "test_pie_runtimes",
                   "-pie", "-fPIC", "test.cpp", "-L#{opt_lib}",
                   "-stdlib=libc++", "-rtlib=compiler-rt",
                   "-static-libstdc++", "-lpthread", "-ldl"
      assert_equal "Hello World!", shell_output("./test_pie_runtimes").chomp
      (testpath/"test_pie_runtimes").dynamically_linked_libraries.each do |lib|
        refute_match(/lib(std)?c\+\+/, lib)
        refute_match(/libgcc/, lib)
        refute_match(/libatomic/, lib)
        refute_match(/libunwind/, lib)
      end

      (testpath/"test_plugin.cpp").write <<~CPP
        #include <iostream>
        __attribute__((visibility("default")))
        extern "C" void run_plugin() {
          std::cout << "Hello Plugin World!" << std::endl;
        }
      CPP
      (testpath/"test_plugin_main.c").write <<~C
        extern void run_plugin();
        int main() {
          run_plugin();
        }
      C
      system bin/"clang++", "-v", "-o", "test_plugin.so",
             "-shared", "-fPIC", "test_plugin.cpp", "-L#{opt_lib}",
             "-stdlib=libc++", "-rtlib=compiler-rt",
             "-static-libstdc++", "-lpthread", "-ldl"
      system bin/"clang", "-v",
             "test_plugin_main.c", "-o", "test_plugin_libc++",
             "test_plugin.so", "-Wl,-rpath=#{testpath}", "-rtlib=compiler-rt"
      assert_equal "Hello Plugin World!", shell_output("./test_plugin_libc++").chomp
      (testpath/"test_plugin.so").dynamically_linked_libraries.each do |lib|
        refute_match(/lib(std)?c\+\+/, lib)
        refute_match(/libgcc/, lib)
        refute_match(/libatomic/, lib)
        refute_match(/libunwind/, lib)
      end

      # OHOS-specific: target-triple runtime libs built by
      # build_ohos_target_runtimes, and an end-to-end cross-compile+run using
      # them (host and target triple share the same physical hardware here).
      rt_root = Pathname.glob("#{lib}/clang/*").first
      assert_path_exists rt_root/"lib"/TARGET_TRIPLE/"libclang_rt.builtins.a"
      assert_path_exists rt_root/"lib"/TARGET_TRIPLE/"clang_rt.crtbegin.o"
      assert_path_exists rt_root/"lib"/TARGET_TRIPLE/"clang_rt.crtend.o"
      assert_path_exists lib/TARGET_TRIPLE/"libc++_static.a"
      assert_path_exists lib/TARGET_TRIPLE/"libc++abi.a"
      assert_path_exists lib/TARGET_TRIPLE/"libunwind.a"
      assert_path_exists lib/TARGET_TRIPLE/"libc++.a"
      assert_path_exists include/TARGET_TRIPLE/"c++/v1/iostream"

      # __n1 is OHOS's mandated ABI namespace for third-party distribution —
      # assert it directly rather than trusting the cmake flag took effect.
      assert_match "_ZN4__n1", shell_output("#{bin}/llvm-nm #{lib/TARGET_TRIPLE}/libc++_static.a")

      ohos_sdk = formula_opt_prefix("ohos-sdk")
      target_sysroot = "#{ohos_sdk}/native/sysroot"
      system bin/"clang++", "-stdlib=libc++", "--target=#{TARGET_TRIPLE}",
             "--sysroot=#{target_sysroot}", "test.cpp", "-o", "test-ohos-target"
      assert_equal "Hello World!", shell_output("./test-ohos-target").chomp
    end

    # Testing mlir
    (testpath/"test.mlir").write <<~MLIR
      func.func @main() {return}

      // -----

      // expected-note @+1 {{see existing symbol definition here}}
      func.func @foo() { return }

      // ----

      // expected-error @+1 {{redefinition of symbol named 'foo'}}
      func.func @foo() { return }
    MLIR
    system bin/"mlir-opt", "--split-input-file", "--verify-diagnostics", "test.mlir"

    (testpath/"scanbuildtest.cpp").write <<~CPP
      #include <iostream>
      int main() {
        int *i = new int;
        *i = 1;
        delete i;
        std::cout << *i << std::endl;
        return 0;
      }
    CPP
    if OS.mac?
      assert_includes shell_output("#{bin}/scan-build make scanbuildtest 2>&1"),
                      "warning: Use of memory after it is freed"
    else
      # OHOS: neither `make` nor `perl` (which scan-build's driver needs) is a
      # system tool here (both are formulae, not guaranteed on PATH in CI) —
      # invoke the static analyzer directly instead, exercising the same
      # clang-tools-extra codepath.
      assert_includes shell_output("#{bin}/clang --analyze --analyzer-output=text scanbuildtest.cpp 2>&1"),
                      "warning: Use of memory after it is freed"
    end

    (testpath/"clangformattest.c").write <<~C
      int    main() {
          printf("Hello world!"); }
    C
    assert_equal "int main() { printf(\"Hello world!\"); }\n",
      shell_output("#{bin}/clang-format -style=google clangformattest.c")

    # This will fail if the clang bindings cannot find `libclang`.
    with_env(PYTHONPATH: prefix/Language::Python.site_packages(python3)) do
      system python3, "-c", <<~PYTHON
        from clang import cindex
        cindex.Config().get_cindex_library()
      PYTHON
    end

    # Ensure LLVM did not regress output of `llvm-config --system-libs` which for a time
    # was known to output incorrect linker flags; e.g., `-llibxml2.tbd` instead of `-lxml2`.
    # On the other hand, note that a fully qualified path to `dylib` or `tbd` is OK, e.g.,
    # `/usr/local/lib/libxml2.tbd` or `/usr/local/lib/libxml2.dylib`.
    abs_path_exts = [".tbd", ".dylib"]
    shell_output("#{bin}/llvm-config --system-libs").chomp.strip.split.each do |lib|
      if lib.start_with?("-l")
        assert !lib.end_with?(".tbd"), "expected abs path when lib reported as .tbd"
        assert !lib.end_with?(".dylib"), "expected abs path when lib reported as .dylib"
      else
        p = Pathname.new(lib)
        if abs_path_exts.include?(p.extname)
          assert p.absolute?, "expected abs path when lib reported as .tbd or .dylib"
        end
      end
    end
  end
end
