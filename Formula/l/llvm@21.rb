class LlvmAT21 < Formula
  desc "LLVM 21 toolchain: clang, lld, OHOS multiarch runtime libs"
  homepage "https://llvm.org/"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-21.1.8/llvm-project-21.1.8.src.tar.xz"
  sha256 "4633a23617fa31a3ea51242586ea7fb1da7140e426bd62fc164261fe036aa142"
  license "Apache-2.0" => { with: "LLVM-exception" }
  revision 1
  # This formula is fully rewritten from upstream because HarmonyOS requires an
  # OHOS code-sign patch (CodeSign.cpp in lld/ELF), config.guess stubbing,
  # and two separate runtime builds (compiler-rt + multiarch libc++/libcxxabi/libunwind).

  livecheck do
    url :stable
    regex(/^llvmorg[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    # Validation tap bottle; when graduating to official core, change root_url → harmonybrew/homebrew-core releases.
    # Tag name does not contain @ (avoids GitHub URL encoding causing brew parsing issues).
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/llvm21-v21.1.8-pruned-r3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "931ef0e5953cdbdc283ef4afbcc32467e01f2eaaddbcc6d2346b38c93ae90982"
  end

  keg_only "this is a versioned HarmonyOS bootstrap toolchain"

  depends_on "cmake"    => :build
  depends_on "ninja"    => :build
  depends_on "python@3.14" => :build
  depends_on "libxml2"
  depends_on "ohos-sdk"
  # Runtime dependency: lld links against libxml2/zlib (must be declared explicitly in a keg_only
  # environment, otherwise the loader cannot find the .so).
  depends_on "zlib"

  # HarmonyOS code-sign support (adds CodeSign.cpp to lld/ELF).  Version-specific
  patch :p1 do
    file "Patches/llvm@21/code-sign.patch"
  end

  HOST_TRIPLE   = "aarch64-unknown-linux-ohos".freeze
  TARGET_TRIPLE = "aarch64-linux-ohos".freeze
  COMPILERS     = %w[clang clang++].freeze

  # Tools borrowed from ohos-sdk (LLVM 15) via relative symlinks.
  # ELF/DWARF/IR formats stable across LLVM 15-21. See slim-llvm21-bottle design §4.3.
  KEEP_TOOLS_FROM_SDK = %w[
    llvm-ar llvm-ranlib llvm-nm llvm-objcopy llvm-objdump
    llvm-readelf llvm-readobj llvm-strip llvm-cxxfilt
    llvm-dwarfdump llvm-cov llvm-profdata llvm-symbolizer llvm-addr2line
    FileCheck not count
  ].freeze

  def install
    ohos_sdk    = Formula["ohos-sdk"].opt_prefix
    sysroot     = "#{ohos_sdk}/native/sysroot"
    libcxx_ohos = "#{ohos_sdk}/native/llvm/include/libcxx-ohos/include/c++/v1"

    odie "OHOS sysroot missing: #{sysroot}/usr/lib" unless File.directory?("#{sysroot}/usr/lib")
    odie "libcxx-ohos headers missing: #{libcxx_ohos}" unless File.directory?(libcxx_ohos)

    patch_config_guess(buildpath/"llvm/cmake/config.guess")

    cmake_modules = buildpath/"cmake-modules"
    (cmake_modules/"Platform").mkpath
    (cmake_modules/"Platform/HarmonyOS.cmake").write <<~CMAKE
      set(CMAKE_DL_LIBS "dl")
      set(CMAKE_SHARED_LIBRARY_RUNTIME_C_FLAG "-Wl,-rpath,")
      set(CMAKE_SHARED_LIBRARY_RUNTIME_C_FLAG_SEP ":")
      set(CMAKE_SHARED_LIBRARY_RPATH_ORIGIN_TOKEN "\\$ORIGIN")
      set(CMAKE_SHARED_LIBRARY_RPATH_LINK_C_FLAG "-Wl,-rpath-link,")
      set(CMAKE_SHARED_LIBRARY_SONAME_C_FLAG "-Wl,-soname,")
      set(CMAKE_EXE_EXPORTS_C_FLAG "-Wl,--export-dynamic")
      set(CMAKE_PLATFORM_USES_PATH_WHEN_NO_SONAME 1)

      foreach(type SHARED_LIBRARY SHARED_MODULE EXE)
        set(CMAKE_${type}_LINK_STATIC_C_FLAGS "-Wl,-Bstatic")
        set(CMAKE_${type}_LINK_DYNAMIC_C_FLAGS "-Wl,-Bdynamic")
      endforeach()

      set(CMAKE_LINK_GROUP_USING_RESCAN "LINKER:--start-group" "LINKER:--end-group")
      set(CMAKE_LINK_GROUP_USING_RESCAN_SUPPORTED TRUE)

      if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
        set(CMAKE_INSTALL_SO_NO_EXE 0 CACHE INTERNAL
          "Install .so files without execute permission.")
      endif()

      include(Platform/UnixPaths)
    CMAKE

    jobs      = ENV.make_jobs
    link_jobs = [jobs / 4, 1].max

    args = %W[
      -DCMAKE_MODULE_PATH=#{cmake_modules}
      -DLLVM_HOST_TRIPLE=#{HOST_TRIPLE}
      -DCMAKE_BUILD_TYPE=Release
      -DCMAKE_INSTALL_PREFIX=#{prefix}
      -DCMAKE_C_COMPILER=clang
      -DCMAKE_CXX_COMPILER=clang++
      -DLLVM_ENABLE_PROJECTS=clang;lld
      -DLLVM_ENABLE_RUNTIMES=libcxx;libcxxabi;libunwind;compiler-rt
      -DLLVM_TARGETS_TO_BUILD=AArch64
      -DLLVM_DEFAULT_TARGET_TRIPLE=#{HOST_TRIPLE}
      -DLLVM_ENABLE_ASSERTIONS=OFF
      -DLLVM_PARALLEL_COMPILE_JOBS=#{jobs}
      -DLLVM_PARALLEL_LINK_JOBS=#{link_jobs}
      -DLLVM_ENABLE_LTO=OFF
      -DLLVM_ENABLE_LLD=ON
      -DLLVM_OPTIMIZED_TABLEGEN=ON
      -DLLVM_INSTALL_UTILS=ON
      -DLLVM_INCLUDE_TESTS=OFF
      -DLLVM_INCLUDE_EXAMPLES=OFF
      -DLLVM_INCLUDE_BENCHMARKS=OFF
      -DLLVM_ENABLE_BINDINGS=OFF
      -DLLVM_ENABLE_LIBCXX=ON
      -DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=OFF
      -DLLVM_ENABLE_TERMINFO=OFF
      -DLIBUNWIND_USE_FRAME_HEADER_CACHE=ON
      -DCLANG_BUILD_EXAMPLES=OFF
      -DCLANG_VENDOR=OHOS
      -DLLVM_ENABLE_ZSTD=FORCE_ON
      -DLLVM_USE_STATIC_ZSTD=ON
      -DBUILD_SHARED_LIBS=OFF
      -DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON
      -DLIBCXX_HAS_MUSL_LIBC=ON
      -DLIBCXX_HAS_PTHREAD_API=ON
      -DLIBCXX_USE_COMPILER_RT=ON
      -DLIBCXXABI_USE_COMPILER_RT=ON
      -DLIBCXXABI_USE_LLVM_UNWINDER=ON
      -DLIBUNWIND_ENABLE_SHARED=OFF
      -DLIBUNWIND_USE_COMPILER_RT=ON
      -DDEFAULT_SYSROOT=#{sysroot}
    ]
    # Multi-word flags must not go in %W[...] — %W splits on whitespace.
    args << "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
    args << "-DCMAKE_C_FLAGS=-D__MUSL__ -fstack-protector-strong " \
            "-no-canonical-prefixes -ffunction-sections -fdata-sections"
    args << "-DCMAKE_CXX_FLAGS=-D__MUSL__ -fstack-protector-strong " \
            "-no-canonical-prefixes -ffunction-sections -fdata-sections"
    rpath_flags = "-Wl,-rpath,$ORIGIN/../lib " \
                  "-Wl,-rpath,#{HOMEBREW_PREFIX}/opt/libxml2/lib " \
                  "-Wl,-rpath,#{HOMEBREW_PREFIX}/opt/zlib/lib"
    common_linker_flags = "-Wl,--code-sign -Wl,--build-id=sha1 " \
                          "-Wl,--gc-sections -Wl,-z,relro,-z,now -Wl,-z,noexecstack #{rpath_flags}"
    args << "-DCMAKE_EXE_LINKER_FLAGS=#{common_linker_flags}"
    args << "-DCMAKE_SHARED_LINKER_FLAGS=#{common_linker_flags}"
    args << "-DCMAKE_MODULE_LINKER_FLAGS=#{common_linker_flags}"
    args << "-DRUNTIMES_CMAKE_ARGS=-DCMAKE_MODULE_PATH=#{cmake_modules}" \
            ";-DCMAKE_SYSROOT=#{sysroot}" \
            ";-DCMAKE_C_FLAGS=-D__MUSL__" \
            ";-DCMAKE_CXX_FLAGS=-D__MUSL__ -isystem #{libcxx_ohos}"

    # --- Bootstrap slim mode (see docs/superpowers/specs/2026-06-24-slim-llvm21-bottle-design.md)
    # Note: CLANG_BUILD_TOOLS=OFF / LLVM_BUILD_TOOLS=OFF would skip clang driver and
    # llvm-config themselves (gates `add_clang_executable` / `add_llvm_tool`), so we
    # keep them ON and prune post-install instead.

    llvmpath = buildpath/"llvm"

    mkdir "build" do
      system "cmake", "-G", "Ninja", llvmpath, *args
      system "ninja", "-j", jobs.to_s, "clang", "lld"
      system "cmake", llvmpath.to_s, "-ULLVM_ENABLE_RUNTIMES", "-DLLVM_ENABLE_RUNTIMES="
      system "ninja", "-j", jobs.to_s, "install"
    end

    sign_dir(bin)
    install_triple_wrappers
    # Link BEFORE build_compiler_rt / build_multiarch_runtimes: symlink targets
    # (ohos-sdk LLVM 15) are functionally equivalent for AR/RANLIB (format stable).
    link_overlapping_tools
    build_compiler_rt(sysroot: sysroot, jobs: jobs)
    build_multiarch_runtimes(sysroot: sysroot, libcxx_ohos: libcxx_ohos, jobs: jobs)

    prune_bootstrap_extras
  end

  def patch_config_guess(config_guess)
    return unless config_guess.exist?
    return if config_guess.read(64).include?("Stubbed for HarmonyOS")

    cp(config_guess, "#{config_guess}.orig")
    # brew extends Pathname#write to refuse overwriting existing files —
    # use File.write to bypass that safety check.
    File.write(config_guess, <<~SH)
      #!/bin/sh
      # Stubbed for HarmonyOS host build — original at config.guess.orig
      echo "#{HOST_TRIPLE}"
    SH
    config_guess.chmod(0755)
  end

  def sign_dir(dir)
    binary_sign = Formula["ohos-sdk"].opt_bin/"binary-sign-tool"
    return opoo "binary-sign-tool not found; binaries left unsigned" unless binary_sign.exist?

    signed = failed = skipped = 0
    mktemp do
      Pathname.glob(dir/"*").each do |f|
        next unless f.file?
        next if f.symlink?
        next if f.binread(4) != "\x7fELF".b

        skipped += 1

        out = Pathname.pwd/f.basename
        ok = quiet_system binary_sign, "sign", "-selfSign", "1",
                          "-inFile", f.to_s, "-outFile", out.to_s
        if ok && out.exist?
          mv(out, f, force: true)
          f.chmod(0755)
          signed += 1
        else
          opoo "sign FAIL: #{f.basename}"
          failed += 1
        end
      end
    end
    ohai "binary-sign-tool: signed=#{signed} skipped=#{skipped} failed=#{failed}"
    odie "#{failed} binary(ies) failed to sign" if failed.positive?
  end

  def install_triple_wrappers
    %w[aarch64-unknown-linux-ohos aarch64-linux-ohos].each do |pfx|
      COMPILERS.each do |t|
        w = bin/"#{pfx}-#{t}"
        # LLVM install already creates triple-prefix wrappers; bypass brew's
        # Pathname#write safety check (refuses overwrite) via File.write.
        File.write(w, <<~SH)
          #!/bin/sh
          exec "$(dirname "$0")/#{t}" --target=#{pfx} "$@"
        SH
        w.chmod(0755)
      end
    end
  end

  def build_compiler_rt(sysroot:, jobs:)
    cc       = bin/"clang"
    cxx      = bin/"clang++"
    ar       = bin/"llvm-ar"
    ranlib   = bin/"llvm-ranlib"
    runtimes = buildpath/"runtimes"

    cflags = "--target=#{TARGET_TRIPLE} --sysroot=#{sysroot} -D__MUSL__ -fPIC"

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
             "-DCMAKE_AR=#{ar}",
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

  def build_multiarch_runtimes(sysroot:, libcxx_ohos:, jobs:)
    cc       = bin/"clang"
    cxx      = bin/"clang++"
    ar       = bin/"llvm-ar"
    ranlib   = bin/"llvm-ranlib"
    runtimes = buildpath/"runtimes"
    libcxxabi_inc = buildpath/"libcxxabi/include"

    cflags = "--target=#{TARGET_TRIPLE} --sysroot=#{sysroot} -D__MUSL__ " \
             "-I#{sysroot}/usr/include -fPIC -fstack-protector-strong " \
             "-funwind-tables -fno-omit-frame-pointer"
    cxxflags_unwind   = "#{cflags} -I#{libcxxabi_inc} -I#{libcxx_ohos} -nostdinc++"
    cxxflags_runtimes = cflags

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
             "-DCMAKE_AR=#{ar}",
             "-DCMAKE_RANLIB=#{ranlib}",
             "-DCMAKE_C_FLAGS=#{cflags}",
             "-DCMAKE_CXX_FLAGS=#{cxxflags_unwind}",
             "-DCMAKE_ASM_FLAGS=#{cflags}",
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
             "-DCMAKE_AR=#{ar}",
             "-DCMAKE_RANLIB=#{ranlib}",
             "-DCMAKE_C_FLAGS=#{cflags}",
             "-DCMAKE_CXX_FLAGS=#{cxxflags_runtimes}",
             "-DCMAKE_INSTALL_PREFIX=#{stage}/libcxx",
             "-DLLVM_ENABLE_RUNTIMES=libunwind;libcxxabi;libcxx",
             "-DLIBCXX_ENABLE_SHARED=OFF",
             "-DLIBUNWIND_ENABLE_SHARED=OFF",
             "-DLIBUNWIND_USE_COMPILER_RT=ON",
             "-DLIBCXXABI_ENABLE_SHARED=OFF",
             "-DLIBCXXABI_USE_COMPILER_RT=ON",
             "-DLIBCXXABI_USE_LLVM_UNWINDER=ON",
             "-DLIBCXX_CXX_ABI=libcxxabi",
             "-DLIBCXX_ABI_NAMESPACE=__h",
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
    unwind_incdir = include
    target_libdir.mkpath
    target_incdir.dirname.mkpath
    (share/"libc++").mkpath

    mv("#{stage}/libcxx/lib/libc++.a",             target_libdir/"libc++_static.a")
    mv("#{stage}/libcxx/lib/libc++abi.a",          target_libdir/"libc++abi.a")
    mv("#{stage}/libcxx/lib/libc++experimental.a", target_libdir/"libc++experimental.a")
    mv("#{stage}/libcxx/lib/libc++.modules.json",  target_libdir/"libc++.modules.json")

    rm("#{stage}/libcxx/lib/libunwind.a")
    mv("#{stage}/libunwind/lib/libunwind.a", target_libdir/"libunwind.a")

    rm_r(target_incdir) if target_incdir.exist?
    mv("#{stage}/libcxx/include/c++/v1", target_incdir)

    %w[__libunwind_config.h libunwind.h libunwind.modulemap
       unwind_arm_ehabi.h unwind_itanium.h unwind.h].each do |h|
      mv("#{stage}/libunwind/include/#{h}", unwind_incdir/h)
    end
    mv("#{stage}/libunwind/include/mach-o", unwind_incdir/"mach-o")

    std_mod_dst = share/"libc++/v1"
    rm_r(std_mod_dst) if std_mod_dst.exist?
    mv("#{stage}/libcxx/share/libc++/v1", std_mod_dst)

    (target_libdir/"libc++.a").write <<~LDSCRIPT
      INPUT(-lc++_static -lc++abi -lunwind)
    LDSCRIPT
  end

  # bin/ entries preserved by prune_bootstrap_extras. Everything else LLVM
  # installed (clang-format / clang-tidy / opt / llc / bugpoint / llvm-exegesis
  # / analyze-build / scan-build / ...) is deleted to slim the bottle.
  # Triple-prefix wrappers and KEEP_TOOLS_FROM_SDK (handled by
  # link_overlapping_tools as symlinks) are also preserved.
  KEEP_BIN_ENTRIES = %w[
    clang clang++ clang-21
    clang-cl clang-cpp
    ld.lld lld ld64.lld lld-link
    llvm-config
    hmaptool
    llvm-tblgen clang-tblgen
  ].freeze

  def prune_bootstrap_extras
    # bin/: keep only KEEP_BIN_ENTRIES + triple wrappers + symlinks (ohos-sdk links).
    Pathname.glob(bin/"*").each do |f|
      name = f.basename.to_s
      next if KEEP_BIN_ENTRIES.include?(name)
      next if /\Aaarch64-(unknown-)?linux-ohos-(clang|clang\+\+)\z/.match?(name)
      next if f.symlink? # preserve ohos-sdk symlinks created by link_overlapping_tools

      rm(f)
    end

    # lib/: delete static libs and large .so (binaries statically link what they need).
    %w[libLLVM*.a libclang*.a liblld*.a
       libclang-cpp.so* libLTO.so* libclang.so*].each do |pat|
      Dir.glob(lib/pat).each { |f| rm(f) }
    end
    rm_r(lib/"scanbuild") if (lib/"scanbuild").exist?

    # include/: drop LLVM internal dev headers (downstream uses libc++ headers only).
    %w[llvm llvm-c clang clang-c lld].each do |sub|
      p = include/sub
      rm_r(p) if p.exist?
    end

    # share/: drop IDE / analysis helpers.
    %w[clang scan-build scan-view opt-viewer man].each do |sub|
      p = share/sub
      rm_r(p) if p.exist?
    end
  end

  def link_overlapping_tools
    # Build relative symlinks for binutils/diagnostic tools that downstream
    # cmake find_program / build scripts expect but we don't ship from v21.
    # Targets are ohos-sdk LLVM 15 (formats stable across LLVM 15-21).
    sdk_bin = Formula["ohos-sdk"].opt_prefix/"native/llvm/bin"
    KEEP_TOOLS_FROM_SDK.each do |t|
      src = sdk_bin/t
      next unless src.exist?

      target = bin/t
      target.unlink if target.exist? || target.symlink?
      target.make_symlink src.relative_path_from(bin)
    end
  end

  def caveats
    <<~EOS
      HarmonyOS LLVM 21 (slim bootstrap build) at:
        #{opt_prefix}

      Default target triple:      #{HOST_TRIPLE}
      Runtime libs target triple: #{TARGET_TRIPLE}

      This is a SLIM build — only what downstream C++23 bootstraps consume:
        ✓ clang/clang++ v21, ld.lld v21 (CodeSign patch), llvm-config
        ✓ multiarch libc++/libunwind/compiler-rt static libs + headers
        ✗ libLLVM*.a / libclang*.a / libclang-cpp.so (use upstream for LLVM dev)
        ✗ clang-format/tidy/clangd, scan-build (use ohos-sdk LLVM 15)

      bin/ tools like llvm-ar/nm/objcopy/objdump/readelf/strip/cov/FileCheck
      are relative symlinks to ohos-sdk LLVM 15 (formats stable across 15-21).

      Example:
        #{opt_bin}/aarch64-linux-ohos-clang++ -stdlib=libc++ \\
          --sysroot=#{HOMEBREW_PREFIX}/opt/ohos-sdk/native/sysroot \\
          hello.cpp -o hello

      For a full LLVM 21 dev environment (all tools + static libs + headers),
      track future `llvm@21-full` formula (not yet implemented).
    EOS
  end

  def post_install
    # Generate cc/c++ shims in HOMEBREW_PREFIX/bin. Both share the same template:
    # LD_LIBRARY_PATH + -o parse + ELF magic check + binary-sign-tool sign + chmod +x.
    # Keeps cc (already hand-crafted) and c++ (was missing sign step) in sync.
    sign_tool = Formula["ohos-sdk"].opt_bin/"binary-sign-tool"
    opoo "binary-sign-tool not found; shims will not auto-sign ELF outputs" unless sign_tool.exist?

    shims = { "cc" => "clang", "c++" => "clang++" }
    shims.each do |shim_name, target|
      shim_path = HOMEBREW_PREFIX/"bin"/shim_name
      File.write(shim_path, <<~SH)
        #!/bin/sh
        # Auto-generated by llvm@21 post_install. Edits will be lost on reinstall.
        # Wraps #{target} with LD_LIBRARY_PATH and auto-signs ELF outputs (OHOS exec/dlopen requirement).
        export LD_LIBRARY_PATH="#{HOMEBREW_PREFIX}/opt/libxml2/lib:#{HOMEBREW_PREFIX}/opt/llvm@21/lib:$LD_LIBRARY_PATH"

        _out=""
        _prev=""
        for _arg in "$@"; do
          [ "$_prev" = "-o" ] && _out="$_arg"
          _prev="$_arg"
        done

        "#{opt_bin}/#{target}" "$@"
        _rc=$?
        [ $_rc -ne 0 ] && exit $_rc

        if [ -n "$_out" ] && [ -f "$_out" ]; then
          _magic=$(head -c4 "$_out" 2>/dev/null | od -An -c | head -1)
          case "$_magic" in
            *"177"*E*L*F*)
              # ELF type byte at offset 16: 1=REL(.o), 2=EXEC, 3=DYN(.node/.so)
              # Skip .o — signing them propagates codesign into linker output
              # and breaks downstream "already exists" sign of the final binary.
              _etype=$(od -An -tu1 -j16 -N1 "$_out" 2>/dev/null | tr -d ' ')
              case "$_etype" in
                2|3)
                  "#{sign_tool}" sign -selfSign 1 -inFile "$_out" -outFile "$_out" >/dev/null 2>&1
                  chmod +x "$_out" 2>/dev/null
                  ;;
              esac
              ;;
          esac
        fi
        exit 0
      SH
      shim_path.chmod(0755)
    end

    ohai "Generated cc/c++ shims in #{HOMEBREW_PREFIX}/bin (LD_LIBRARY_PATH + ELF auto-sign)"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/clang --version")
    assert_match HOST_TRIPLE,  shell_output("#{bin}/clang --version")

    %w[aarch64-unknown-linux-ohos aarch64-linux-ohos].each do |pfx|
      COMPILERS.each do |t|
        assert_path_exists bin/"#{pfx}-#{t}"
      end
    end

    ohos_sdk = Formula["ohos-sdk"].opt_prefix
    sysroot  = "#{ohos_sdk}/native/sysroot"

    rt_root = Pathname.glob("#{lib}/clang/*").first
    assert_path_exists rt_root/"lib"/TARGET_TRIPLE/"libclang_rt.builtins.a"
    assert_path_exists rt_root/"lib"/TARGET_TRIPLE/"clang_rt.crtbegin.o"
    assert_path_exists rt_root/"lib"/TARGET_TRIPLE/"clang_rt.crtend.o"
    assert_path_exists lib/TARGET_TRIPLE/"libc++_static.a"
    assert_path_exists lib/TARGET_TRIPLE/"libc++abi.a"
    assert_path_exists lib/TARGET_TRIPLE/"libunwind.a"
    assert_path_exists lib/TARGET_TRIPLE/"libc++.a"
    assert_path_exists include/TARGET_TRIPLE/"c++/v1/iostream"

    (testpath/"hello.cpp").write <<~CPP
      #include <iostream>
      int main() { std::cout << "hi\\n"; return 0; }
    CPP
    system bin/"aarch64-linux-ohos-clang++", "-stdlib=libc++",
           "--sysroot=#{sysroot}", "hello.cpp", "-o", "hello"
    assert_path_exists testpath/"hello"
  end
end
