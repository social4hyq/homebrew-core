class LldAT21 < Formula
  desc "LLVM Project Linker"
  homepage "https://lld.llvm.org/"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-21.1.8/llvm-project-21.1.8.src.tar.xz"
  sha256 "4633a23617fa31a3ea51242586ea7fb1da7140e426bd62fc164261fe036aa142"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0" => { with: "LLVM-exception" }
  revision 2
  compatibility_version 1

  livecheck do
    formula "llvm@21"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4d5ba652b74c77b96d7690202d41229d2f389d74072fdbec899a6294563a6807"
  end

  keg_only :versioned_formula

  depends_on "cmake" => :build
  depends_on "llvm@21"
  depends_on "zstd"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # Adds a `.codesign` section to every ELF this linker produces,
  # defaulting the equivalent of --code-sign to ON (every executable ELF
  # on OHOS must carry one to run).
  patch do
    file "Patches/lld@21/0001-ohos-code-sign.patch"
  end

  def install
    system "cmake", "-S", "lld", "-B", "build",
                    "-DBUILD_SHARED_LIBS=ON",
                    "-DCMAKE_INSTALL_RPATH=#{rpath}",
                    "-DLLD_VENDOR=#{tap&.user}",
                    # `find_package(LLVM)` resolves through
                    # `CMAKE_PREFIX_PATH`, where the keg-only `ohos-sdk-native`
                    # (pulled in by `llvm@21`) is searched ahead of `llvm@21`'s
                    # prefix — the SDK's bundled LLVM 15 CMake package would win
                    # the lookup. `LLVM_DIR` is checked first, so it pins the
                    # intended keg.
                    "-DLLVM_DIR=#{formula_opt_lib("llvm@21")}/cmake/llvm",
                    # Upstream has this `ON`, but on OHOS clang's `-flto` bitcode
                    # is rejected by the only linker on PATH, `ohos-sdk`'s LLD
                    # 15.0.4.
                    "-DLLVM_ENABLE_LTO=OFF",
                    "-DLLVM_INCLUDE_TESTS=OFF",
                    "-DLLVM_USE_SYMLINKS=ON",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    if OS.linux?
      # ENV.cc must be this keg's own clang, not ohos-sdk's — the
      # -fuse-ld= PATH-priority check just below depends on it.
      llvm = Formula["llvm@21"]
      ENV["CC"] = (llvm.opt_bin/"clang").to_s
      ENV["CXX"] = (llvm.opt_bin/"clang++").to_s
    end

    assert_match(/LLD 21\./, shell_output("#{bin}/wasm-ld --version"))

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
      readelf = formula_opt_bin("llvm@21")/"llvm-readelf"

      system ENV.cc, "-fuse-ld=lld", "test.c", "-o", "test-signed"
      assert_match ".codesign", shell_output("#{readelf} -S test-signed")

      system ENV.cc, "-fuse-ld=lld", "-Wl,--no-code-sign", "test.c", "-o", "test-unsigned"
      refute_match ".codesign", shell_output("#{readelf} -S test-unsigned")
    end
  end
end
