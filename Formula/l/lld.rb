class Lld < Formula
  desc "LLVM Project Linker"
  homepage "https://lld.llvm.org/"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-23.1.1/llvm-project-23.1.1.src.tar.xz"
  sha256 "ebe9be46fe8756d58c5b198ffad0fa2a766257add81a4dc52179bfacc7888ee6"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0" => { with: "LLVM-exception" }
  compatibility_version 2
  head "https://github.com/llvm/llvm-project.git", branch: "main"
  revision 1

  livecheck do
    formula "llvm"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5a24139a6c1194d0ddb915c36221d396325907786439023f357beafa55e6826c"
  end

  conflicts_with "ohos-sdk", because: "both install `lld` binaries"

  depends_on "cmake" => :build
  depends_on "llvm"
  depends_on "zstd"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # These used to be part of LLVM.
  link_overwrite "bin/lld", "bin/ld64.lld", "bin/ld.lld", "bin/lld-link", "bin/wasm-ld"
  link_overwrite "include/lld/*", "lib/cmake/lld/*"

  # Adds a `.codesign` section to every ELF this linker produces,
  # defaulting the equivalent of --code-sign to ON (every executable ELF
  # on OHOS must carry one to run).
  patch do
    file "Patches/lld/0001-ohos-code-sign.patch"
  end

  def install
    system "cmake", "-S", "lld", "-B", "build",
                    "-DBUILD_SHARED_LIBS=ON",
                    "-DCMAKE_INSTALL_RPATH=#{rpath}",
                    "-DLLD_VENDOR=#{tap&.user}",
                    # `find_package(LLVM)` resolves through
                    # `CMAKE_PREFIX_PATH`, where the keg-only `ohos-sdk-native`
                    # (pulled in by `llvm`) is searched ahead of `llvm`'s
                    # prefix — the SDK's bundled LLVM 15 CMake package would win
                    # the lookup. `LLVM_DIR` is checked first, so it pins the
                    # intended `llvm` keg.
                    "-DLLVM_DIR=#{formula_opt_lib("llvm")}/cmake/llvm",
                    # Upstream has this `ON`, but on OHOS clang 23's `-flto`
                    # bitcode is rejected by the only linker on PATH,
                    # `ohos-sdk`'s LLD 15.0.4 ("Invalid attribute group entry
                    # (Producer: 'LLVM23.1.1' Reader: 'LLVM 15.0.4')").
                    "-DLLVM_ENABLE_LTO=OFF",
                    "-DLLVM_INCLUDE_TESTS=OFF",
                    "-DLLVM_USE_SYMLINKS=ON",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    man1.install Utils::Gzip.compress("lld/docs/ld.lld.1")
  end

  test do
    if OS.linux?
      # ENV.cc must be this keg's own clang, not ohos-sdk's — the
      # -fuse-ld= PATH-priority check just below depends on it.
      llvm = Formula["llvm"]
      ENV["CC"] = (llvm.opt_bin/"clang").to_s
      ENV["CXX"] = (llvm.opt_bin/"clang++").to_s
    end

    assert_match(/LLD 23\./, shell_output("#{bin}/wasm-ld --version"))

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
      readelf = formula_opt_bin("llvm")/"llvm-readelf"

      system ENV.cc, "-fuse-ld=lld", "test.c", "-o", "test-signed"
      assert_match ".codesign", shell_output("#{readelf} -S test-signed")

      system ENV.cc, "-fuse-ld=lld", "-Wl,--no-code-sign", "test.c", "-o", "test-unsigned"
      refute_match ".codesign", shell_output("#{readelf} -S test-unsigned")
    end
  end
end
