class LlvmAT21 < Formula
  desc "Next-gen compiler infrastructure"
  homepage "https://llvm.org/"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-21.1.8/llvm-project-21.1.8.src.tar.xz"
  sha256 "4633a23617fa31a3ea51242586ea7fb1da7140e426bd62fc164261fe036aa142"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0" => { with: "LLVM-exception" }
  revision 7
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^llvmorg[._-]v?(21(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/llvm@21-v21.1.8-r5"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1dd9397b9f900c9b97643c616f7ed33b9d6ea5536c859efa5e769fffa0905b28"
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
  # HOST_TRIPLE must be passed explicitly (see install()) rather than left for
  # LLVM to infer via config.guess/`uname -s`: every real build of this
  # formula runs inside a Docker container (bare-metal builds are blocked by
  # Homebrew itself), and containers share their host's kernel — `uname -s`
  # there reports "Linux", not "HarmonyOS", even though the userland is
  # OHOS/musl. Inference would silently produce aarch64-unknown-linux-*gnu*.
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

    # libc++'s locale_base_api dispatch picks support/linux.h (the glibc
    # xlocale API) for any __linux__ target, musl included — OHOS defines
    # __linux__ too. musl's isdigit_l/strcoll_l/etc are real symbols but
    # their declarations in <ctype.h>/<string.h>/etc are gated behind
    # _GNU_SOURCE/_BSD_SOURCE/_XOPEN_SOURCE, and something earlier in the
    # libc++ header chain already pins those feature-test macros to a
    # narrower POSIX profile before ctype.h is reached, so support/linux.h's
    # unconditional calls hit "undeclared identifier" instead of a missing
    # symbol. There's already a working fallback for this: the older
    # __locale_dir/locale_base_api/musl.h path (calls the non-`_l` musl
    # functions directly), reached only when __linux__ isn't matched here —
    # route musl there instead of down the glibc-shaped path.
    inreplace "libcxx/include/__locale_dir/locale_base_api.h",
              "#  elif defined(__linux__)",
              "#  elif defined(__linux__) && !_LIBCPP_HAS_MUSL_LIBC"

    projects = %w[
      clang
      clang-tools-extra
      mlir
      polly
    ]
    # compiler-rt is deliberately absent here (unlike upstream's list): it
    # was only needed as a link-time dependency (crtbeginS.o) of this same
    # host build's own *shared* libunwind.so/libc++.so, but those are now
    # built static-only (see LIBCXX_ENABLE_SHARED etc. below) — static
    # archives don't need crtbegin/crtend at all. Building it here instead
    # pulls in far more than builtins (GWP-ASan → sanitizer_common, which
    # doesn't compile against this musl sysroot: linux/sysinfo.h and
    # sys/sysinfo.h both define `struct sysinfo`, a known musl/kernel-UAPI
    # header clash), for no benefit — OHOS's clang driver never searches
    # this host-triple location anyway (it wants
    # lib/clang/<ver>/lib/aarch64-linux-ohos/); build_ohos_target_runtimes
    # below builds a target-triple compiler-rt at the path it actually
    # searches, independently of this host bootstrap.
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
    ]

    if tap.present?
      args += %W[
        -DPACKAGE_VENDOR=#{tap.user}
        -DBUG_REPORT_URL=#{tap.issues_url}
      ]
      args << "-DCLANG_VENDOR_UTI=sh.brew.clang" if tap.official?
    end

    runtimes_cmake_args = []
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
      # Explicit, not inferred (see HOST_TRIPLE comment above): this also
      # fixes the *target* triple LLVM_ENABLE_RUNTIMES' nested "runtimes-bins"
      # sub-build uses for compiler-rt/libcxx/libunwind, which otherwise
      # inherits whatever config.guess inferred and silently drifts to
      # aarch64-unknown-linux-gnu inside a Linux-kernel container.
      args << "-DLLVM_HOST_TRIPLE=#{HOST_TRIPLE}"
      args << "-DLLVM_DEFAULT_TARGET_TRIPLE=#{HOST_TRIPLE}"
      # Parts of Polly fail to correctly build with PIC when being used for DSOs.
      args << "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
      # Overrides LLVM_TARGETS_TO_BUILD=all above (last -D wins): this is a
      # bootstrap compiler for OHOS/aarch64 tooling, not a general multi-arch
      # dev toolchain, and `all` roughly doubles build time for ~15 backends
      # nothing downstream targets.
      args << "-DLLVM_TARGETS_TO_BUILD=AArch64"
      runtimes_cmake_args += %w[
        -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
      ]
      # OHOS has no system libc++ (or libstdc++) for the runtimes-configure
      # sub-cmake's compiler-flag probes (check_cxx_compiler_flag etc.) to
      # link a trial executable against — we're building libc++ itself in
      # this very step. Without this, probes that need to *link* (most of
      # them; a bare compile-only flag test like -funwind-tables still
      # passes) fail, which cascades into libunwind/src/CMakeLists.txt's
      # `NOT (CXX_SUPPORTS_FNO_EXCEPTIONS_FLAG AND ...)` hard error. Forcing
      # try_compile to stop at a static archive (no link) is the standard
      # workaround for probing a compiler against a runtime that doesn't
      # exist yet.
      runtimes_cmake_args << "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY"
      runtimes_cmake_args += %w[
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
      # {LIBCXX,LIBCXXABI,LIBUNWIND}_ENABLE_SHARED all default ON upstream,
      # but every .so these runtimes build needs OHOS-driver-specific
      # crtbeginS.o/crtendS.o objects that compiler-rt's crt component
      # doesn't produce under that name (only the non-S clang_rt.crtbegin/
      # crtend used for non-shared links) — first hit trying to link
      # libunwind.so. Same static-only choice build_ohos_target_runtimes
      # below already makes for the target-triple copies; the host copies
      # here are for this build's own internal self-hosting linkage only,
      # so there's no shared-library consumer to lose.
      runtimes_cmake_args += %w[
        -DLIBCXX_ENABLE_SHARED=OFF
        -DLIBCXXABI_ENABLE_SHARED=OFF
        -DLIBUNWIND_ENABLE_SHARED=OFF
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
    # not needed here: clang's own `LINKER:` driver syntax already expands it
    # to `-Xlinker --version-script -Xlinker ...` correctly (verified in CI —
    # libclang-cpp.so links fine without any inreplace for this).
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

    # OHOS's clang driver always adds both include/c++/v1 (host) and this
    # include/#{TARGET_TRIPLE}/c++/v1 dir to the system header search path,
    # even for a plain host compile (getMultiarchTriple() normalizes
    # aarch64 to this triple unconditionally, regardless of --target=).
    # libc++'s C-library wrapper headers (ctype.h, math.h, string.h, ...)
    # use __has_include_next(<foo.h>) to chain past themselves to the real
    # musl header. With an identical wrapper also sitting in this second
    # directory, the chain resolves to *that* wrapper instead (same
    # _LIBCPP_*_H include guard already set, so it's a silent no-op) and
    # never reaches the sysroot's real header — breaking FP_NORMAL,
    # isdigit_l, wint_t and everything else musl's headers actually
    # provide. Host and target headers are otherwise byte-identical (same
    # libc, same ABI, only the triple string differs); drop just the
    # chaining wrapper files here so both host and --target=#{TARGET_TRIPLE}
    # compiles fall through to the sysroot instead of shadowing it.
    target_incdir.glob("**/*.h").each do |f|
      f.unlink if f.read.include?("__has_include_next")
    end

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
        `-shared` is not yet supported (needs crtbeginS.o/crtendS.o, which
          nothing on this platform currently provides) — link executables,
          not shared libraries, with this compiler.

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

    # OHOS: confirms LLVM_HOST_TRIPLE was actually honored (see install()).
    assert_match HOST_TRIPLE, shell_output("#{bin}/clang --version") if OS.linux?

    # OHOS: OHOS::computeSysRoot() only consults Driver::SysRoot (set from
    # DEFAULT_SYSROOT at driver construction) or falls back to
    # <bin>/../../sysroot, which doesn't exist in this keg. Pass it
    # explicitly everywhere below rather than relying on the compiled-in
    # default. (This alone isn't sufficient for libc++'s C-header wrappers
    # to see real musl declarations like FP_NORMAL/isdigit_l/wint_t — that
    # required a separate fix in build_ohos_target_runtimes/install() to
    # the __has_include_next chain; see the comment there.)
    sysroot = "#{formula_opt_prefix("ohos-sdk")}/native/sysroot" if OS.linux?

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

    # See the OHOS sysroot comment above: pass it explicitly, don't rely on
    # the compiled-in DEFAULT_SYSROOT alone.
    sysroot_args = OS.linux? ? ["--sysroot=#{sysroot}"] : []

    system bin/"clang-cpp", "-v", *sysroot_args, "test.c"
    system bin/"clang-cpp", "-v", *sysroot_args, "test.cpp"

    # Testing default toolchain and SDK location.
    system bin/"clang++", "-v", *sysroot_args,
           "-std=c++11", "test.cpp", "-o", "test++"
    assert_includes MachO::Tools.dylibs("test++"), "/usr/lib/libc++.1.dylib" if OS.mac?
    assert_equal "Hello World!", shell_output("./test++").chomp
    system bin/"clang", "-v", *sysroot_args, "test.c", "-o", "test"
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
      system bin/"clang++", "-v", *sysroot_args,
             "-isystem", "#{opt_include}/c++/v1",
             "-std=c++11", "-stdlib=libc++", "test.cpp", "-o", "testlibc++",
             "-rtlib=compiler-rt", "-L#{cxx_libdir}", "-Wl,-rpath,#{cxx_libdir}"
      if OS.mac?
        assert_includes (testpath/"testlibc++").dynamically_linked_libraries,
                        (cxx_libdir/shared_library("libc++", "1")).to_s
      else
        # OHOS: {LIBCXX,LIBCXXABI,LIBUNWIND}_ENABLE_SHARED=OFF above (no
        # crtbeginS.o-equivalent for this driver to link a .so against) —
        # libc++ is statically linked in, so assert its *absence* from the
        # dynamic dependency list instead of presence.
        refute_includes (testpath/"testlibc++").dynamically_linked_libraries,
                        (cxx_libdir/shared_library("libc++", "1")).to_s
      end
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

      system bin/"clang++", "-v", *sysroot_args, "-o", "test_pie_runtimes",
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

      # Upstream also builds a -shared C++ plugin here. Skipped on OHOS:
      # `-shared` needs crtbeginS.o/crtendS.o, which nothing on this platform
      # provides — ohos-sdk's sysroot doesn't ship them, and compiler-rt's
      # crt component (which supplies them on bare-metal-style targets)
      # doesn't build here either (COMPILER_RT_BUILD_CRT is gated behind
      # COMPILER_RT_HAS_CRT, which evaluates false for this target and
      # can't be forced via a normal -D). Known gap, not exercised by
      # anything this formula itself needs (self-hosting only needs
      # executables); revisit if a downstream consumer needs `-shared`.

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
      # It's an inline namespace *nested inside* std (mangled as `4__n1`
      # right after std's `St` substitution, e.g. `_ZNSt4__n1...`), not a
      # top-level namespace — don't anchor the match on `_ZN` immediately
      # preceding it.
      assert_match "4__n1", shell_output("#{bin}/llvm-nm #{lib/TARGET_TRIPLE}/libc++_static.a")

      system bin/"clang++", "-stdlib=libc++", "--target=#{TARGET_TRIPLE}",
             "--sysroot=#{sysroot}", "test.cpp", "-o", "test-ohos-target"
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
      # clang-tools-extra codepath. `--analyzer-output=text` (with `=`)
      # mis-splits as `-analyzer-output =text` and fails to parse; the
      # space-separated form works.
      assert_includes shell_output(
        "#{bin}/clang --analyze --analyzer-output text --sysroot=#{sysroot} scanbuildtest.cpp 2>&1",
      ), "warning: Use of memory after it is freed"
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
