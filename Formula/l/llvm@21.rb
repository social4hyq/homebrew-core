class LlvmAT21 < Formula
  desc "LLVM 21 toolchain for HarmonyOS (clang + lld + OHOS multiarch runtime libs for aarch64-linux-ohos)"
  homepage "https://llvm.org/"
  license "Apache-2.0" => { with: "LLVM-exception" }

  stable do
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-21.1.8/llvm-project-21.1.8.src.tar.xz"
    sha256 "4633a23617fa31a3ea51242586ea7fb1da7140e426bd62fc164261fe036aa142"
  end

  bottle do
    # 验证 tap 的 bottle;毕业后改 root_url → harmonybrew/homebrew-core releases
    root_url "https://github.com/social4hyq/homebrew-core/releases/download/llvm@21-v21.1.8"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0ce8717c57f10569371e0f517d28b32525cd38b4c4f8e2c346d29d6d840c831f"
  end

  livecheck do
    url :stable
    regex(/^llvmorg[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  keg_only "this is a versioned HarmonyOS bootstrap toolchain"

  depends_on "cmake"    => :build
  depends_on "ninja"    => :build
  depends_on "ohos-sdk"

  # HarmonyOS code-sign support (adds CodeSign.cpp to lld/ELF).  Version-specific
  patch :p1 do
    file "Patches/llvm@21/code-sign.patch"
  end

  HOST_TRIPLE   = "aarch64-unknown-linux-ohos".freeze
  TARGET_TRIPLE = "aarch64-linux-ohos".freeze

  def install
    ohos_sdk    = Formula["ohos-sdk"].opt_prefix
    sysroot     = "#{ohos_sdk}/native/sysroot"
    libcxx_ohos = "#{ohos_sdk}/native/llvm/include/libcxx-ohos/include/c++/v1"

    odie "OHOS sysroot missing: #{sysroot}/usr/lib"  unless File.directory?("#{sysroot}/usr/lib")
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
    args << "-DCMAKE_C_FLAGS=-D__MUSL__ -fstack-protector-strong -no-canonical-prefixes -ffunction-sections -fdata-sections"
    args << "-DCMAKE_CXX_FLAGS=-D__MUSL__ -fstack-protector-strong -no-canonical-prefixes -ffunction-sections -fdata-sections"
    args << "-DCMAKE_EXE_LINKER_FLAGS=-Wl,--code-sign -Wl,--build-id=sha1 -Wl,--gc-sections -Wl,-z,relro,-z,now -Wl,-z,noexecstack"
    args << "-DCMAKE_SHARED_LINKER_FLAGS=-Wl,--code-sign -Wl,--build-id=sha1 -Wl,--gc-sections -Wl,-z,relro,-z,now -Wl,-z,noexecstack"
    args << "-DCMAKE_MODULE_LINKER_FLAGS=-Wl,--code-sign -Wl,--build-id=sha1 -Wl,--gc-sections -Wl,-z,relro,-z,now -Wl,-z,noexecstack"
    args << "-DRUNTIMES_CMAKE_ARGS=-DCMAKE_MODULE_PATH=#{cmake_modules}" \
            ";-DCMAKE_SYSROOT=#{sysroot}" \
            ";-DCMAKE_C_FLAGS=-D__MUSL__" \
            ";-DCMAKE_CXX_FLAGS=-D__MUSL__ -isystem #{libcxx_ohos}"

    llvmpath = buildpath/"llvm"

    mkdir "build" do
      system "cmake", "-G", "Ninja", llvmpath, *args
      system "ninja", "-j", jobs.to_s, "clang", "lld"
      system "cmake", llvmpath.to_s, "-ULLVM_ENABLE_RUNTIMES", "-DLLVM_ENABLE_RUNTIMES="
      system "ninja", "-j", jobs.to_s, "install"
    end

    sign_dir(bin)
    install_triple_wrappers
    build_compiler_rt(sysroot: sysroot, jobs: jobs)
    build_multiarch_runtimes(sysroot: sysroot, libcxx_ohos: libcxx_ohos, jobs: jobs)
  end

  def patch_config_guess(cg)
    return unless cg.exist?
    return if cg.read(64).include?("Stubbed for HarmonyOS")
    FileUtils.cp(cg, "#{cg}.orig")
    # brew extends Pathname#write to refuse overwriting existing files —
    # use File.write to bypass that safety check.
    File.write(cg, <<~SH)
      #!/bin/sh
      # Stubbed for HarmonyOS host build — original at config.guess.orig
      echo "#{HOST_TRIPLE}"
    SH
    cg.chmod(0755)
  end

  def sign_dir(dir)
    binary_sign = Formula["ohos-sdk"].opt_bin/"binary-sign-tool"
    return opoo "binary-sign-tool not found; binaries left unsigned" unless binary_sign.exist?

    signed = failed = skipped = 0
    mktemp do
      Pathname.glob(dir/"*").each do |f|
        next unless f.file?
        next if f.symlink?
        next unless f.binread(4) == "\x7fELF".b
        skipped += 1

        out = Pathname.pwd/f.basename
        ok = quiet_system binary_sign, "sign", "-selfSign", "1",
                          "-inFile", f.to_s, "-outFile", out.to_s
        if ok && out.exist?
          FileUtils.mv(out, f, force: true)
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
      %w[clang clang++].each do |t|
        w = bin/"#{pfx}-#{t}"
        w.write <<~SH
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
    rt_tgt  = rt_root/"lib"/TARGET_TRIPLE
    rt_tgt.mkpath

    mkdir buildpath/"compiler-rt-build" do
      system "cmake", "-G", "Ninja",
             "-DCMAKE_SYSTEM_NAME=Linux",
             "-DCMAKE_SYSTEM_PROCESSOR=aarch64",
             "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY",
             "-DCMAKE_C_COMPILER=#{cc}",
             "-DCMAKE_CXX_COMPILER=#{cxx}",
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
      FileUtils.cp(f, rt_tgt/base)
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
      -DCMAKE_REQUIRED_FLAGS=--target=#{TARGET_TRIPLE}\;--sysroot=#{sysroot}
    ]

    stage = buildpath/"multiarch-runtimes-stage"
    (stage/"libunwind").mkpath
    (stage/"libcxx").mkpath

    mkdir buildpath/"multiarch-libunwind" do
      system "cmake", "-G", "Ninja",
             *cmake_runtime,
             "-DCMAKE_C_COMPILER=#{cc}",
             "-DCMAKE_CXX_COMPILER=#{cxx}",
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

    FileUtils.mv("#{stage}/libcxx/lib/libc++.a",             target_libdir/"libc++_static.a")
    FileUtils.mv("#{stage}/libcxx/lib/libc++abi.a",          target_libdir/"libc++abi.a")
    FileUtils.mv("#{stage}/libcxx/lib/libc++experimental.a", target_libdir/"libc++experimental.a")
    FileUtils.mv("#{stage}/libcxx/lib/libc++.modules.json",  target_libdir/"libc++.modules.json")

    FileUtils.rm("#{stage}/libcxx/lib/libunwind.a")
    FileUtils.mv("#{stage}/libunwind/lib/libunwind.a", target_libdir/"libunwind.a")

    target_incdir.rmtree if target_incdir.exist?
    FileUtils.mv("#{stage}/libcxx/include/c++/v1", target_incdir)

    %w[__libunwind_config.h libunwind.h libunwind.modulemap
       unwind_arm_ehabi.h unwind_itanium.h unwind.h].each do |h|
      FileUtils.mv("#{stage}/libunwind/include/#{h}", unwind_incdir/h)
    end
    FileUtils.mv("#{stage}/libunwind/include/mach-o", unwind_incdir/"mach-o")

    std_mod_dst = share/"libc++/v1"
    std_mod_dst.rmtree if std_mod_dst.exist?
    FileUtils.mv("#{stage}/libcxx/share/libc++/v1", std_mod_dst)

    (target_libdir/"libc++.a").write <<~LDSCRIPT
      INPUT(-lc++_static -lc++abi -lunwind)
    LDSCRIPT
  end

  def caveats
    <<~EOS
      HarmonyOS LLVM 21 (clang + lld + OHOS multiarch runtime libs) at:
        #{opt_prefix}

      Default target triple:    #{HOST_TRIPLE}
      Runtime libs target triple: #{TARGET_TRIPLE}

      Example:
        #{opt_bin}/aarch64-linux-ohos-clang++ -stdlib=libc++ \\
          --sysroot=#{HOMEBREW_PREFIX}/opt/ohos-sdk/native/sysroot \\
          hello.cpp -o hello
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/clang --version")
    assert_match HOST_TRIPLE,  shell_output("#{bin}/clang --version")

    %w[aarch64-unknown-linux-ohos aarch64-linux-ohos].each do |pfx|
      %w[clang clang++].each do |t|
        assert_predicate bin/"#{pfx}-#{t}", :exist?
      end
    end

    ohos_sdk = Formula["ohos-sdk"].opt_prefix
    sysroot  = "#{ohos_sdk}/native/sysroot"

    rt_root = Pathname.glob("#{lib}/clang/*").first
    assert_predicate rt_root/"lib"/TARGET_TRIPLE/"libclang_rt.builtins.a", :exist?
    assert_predicate rt_root/"lib"/TARGET_TRIPLE/"clang_rt.crtbegin.o",    :exist?
    assert_predicate rt_root/"lib"/TARGET_TRIPLE/"clang_rt.crtend.o",      :exist?
    assert_predicate lib/TARGET_TRIPLE/"libc++_static.a",                   :exist?
    assert_predicate lib/TARGET_TRIPLE/"libc++abi.a",                       :exist?
    assert_predicate lib/TARGET_TRIPLE/"libunwind.a",                       :exist?
    assert_predicate lib/TARGET_TRIPLE/"libc++.a",                          :exist?
    assert_predicate include/TARGET_TRIPLE/"c++/v1/iostream",               :exist?

    (testpath/"hello.cpp").write <<~CPP
      #include <iostream>
      int main() { std::cout << "hi\\n"; return 0; }
    CPP
    system bin/"aarch64-linux-ohos-clang++", "-stdlib=libc++",
           "--sysroot=#{sysroot}", "hello.cpp", "-o", "hello"
    assert_predicate testpath/"hello", :exist?
  end
end
