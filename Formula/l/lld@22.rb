class LldAT22 < Formula
  desc "LLVM Project Linker"
  homepage "https://lld.llvm.org/"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-22.1.8/llvm-project-22.1.8.src.tar.xz"
  sha256 "922f1817a0df7b1489272d18134ee0087a8b068828f87ac63b9861b1a9965888"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0" => { with: "LLVM-exception" }

  livecheck do
    formula "llvm@22"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e9d2c352d94a396f175c282db68605f985321c563e02277572a3955d81f856df"
  end

  # Not `:versioned_formula`: the fork auto-links versioned kegs on direct
  # install, colliding with ohos-sdk's own ld.lld/lld on PATH.
  keg_only "it conflicts with `ohos-sdk`"

  depends_on "cmake" => :build
  depends_on "llvm@22"
  depends_on "zstd"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # Adds a `.codesign` section to every ELF this linker produces,
  # defaulting the equivalent of --code-sign to ON (every executable ELF
  # on OHOS must carry one to run).
  patch do
    file "Patches/lld@22/0001-ohos-code-sign.patch"
  end

  def install
    rpaths = [rpath]
    rpaths << formula_opt_lib("llvm@22").to_s if OS.linux?

    system "cmake", "-S", "lld", "-B", "build",
                    "-DBUILD_SHARED_LIBS=ON",
                    "-DCMAKE_INSTALL_RPATH=#{rpaths.join(";")}",
                    "-DLLD_BUILT_STANDALONE=ON",
                    "-DLLD_VENDOR=#{tap&.user}",
                    "-DLLVM_CMAKE_DIR=#{formula_opt_lib("llvm@22")}/cmake/llvm",
                    "-DLLVM_ENABLE_LTO=ON",
                    "-DLLVM_INCLUDE_TESTS=OFF",
                    "-DLLVM_USE_SYMLINKS=ON",
                    # The OHOS driver defaults executables to
                    # `--no-allow-shlib-undefined`; liblldCommon.so ends up with
                    # an unresolved `__cxa_thread_atexit_impl` (resolved at load
                    # time from OHOS musl, which exports it) — tolerate it.
                    "-DCMAKE_EXE_LINKER_FLAGS=-Wl,--allow-shlib-undefined",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    if OS.linux?
      # ENV.cc must be this keg's own clang, not ohos-sdk's — the
      # -fuse-ld= PATH-priority check just below depends on it.
      llvm = Formula["llvm@22"]
      ENV["CC"] = (llvm.opt_bin/"clang").to_s
      ENV["CXX"] = (llvm.opt_bin/"clang++").to_s
    end

    assert_match(/LLD 22\./, shell_output("#{bin}/wasm-ld --version"))

    (testpath/"bin/lld").write <<~SHELL
      #!/bin/bash
      exit 1
    SHELL
    chmod "+x", "bin/lld"

    (testpath/"bin").install_symlink "lld" => "ld64.lld"
    (testpath/"bin").install_symlink "lld" => "ld.lld"

    (testpath/"test.c").write <<~C
      #include <stdio.h>
      int main() {
        printf("hello, world!");
        return 0;
      }
    C

    error_message = case ENV.compiler
    when /^gcc(-\d+)?$/ then "ld returned 1 exit status"
    when :clang then "linker command failed"
    else odie "unexpected compiler"
    end

    # Check that the `-fuse-ld=lld` flag actually picks up LLD from PATH.
    ENV.prepend_path "PATH", bin
    with_env(PATH: "#{testpath}/bin:#{ENV["PATH"]}") do
      assert_match error_message, shell_output("#{ENV.cc} -v -fuse-ld=lld test.c 2>&1", 1)
    end

    system ENV.cc, "-v", "-fuse-ld=lld", "test.c", "-o", "test"
    assert_match "hello, world!", shell_output("./test")

    # Code-sign is this patch's default; --no-code-sign turns it off.
    if OS.linux?
      readelf = formula_opt_bin("llvm@22")/"llvm-readelf"

      system ENV.cc, "-fuse-ld=lld", "test.c", "-o", "test-signed"
      assert_match ".codesign", shell_output("#{readelf} -S test-signed")

      system ENV.cc, "-fuse-ld=lld", "-Wl,--no-code-sign", "test.c", "-o", "test-unsigned"
      refute_match ".codesign", shell_output("#{readelf} -S test-unsigned")
    end
  end
end
