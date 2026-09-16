class OhosSdkNative < Formula
  desc "OpenHarmony SDK native component (LLVM toolchain and sysroot)"
  homepage "https://gitcode.com/openharmony"
  url "https://cidownload.openharmony.cn/version/Master_Version/ohos-sdk-public_ohos/20260330_020501/version-Master_Version-ohos-sdk-public_ohos-20260330_020501-ohos-sdk-public_ohos.tar.gz"
  version "26.0.0.18"
  sha256 "191094c9efcc4c0a6874aadaec5a1bf8b16f09f60c8f34a828d4ab0007356248"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "95b9778036ea4dd4edb8ffa48ce8c8ac3bb92324dd801829b1f41d62d97c82be"
  end

  # This formula installs a single package of the official SDK, `ohos-sdk`
  # depends on all of them and stays the only formula exposing the SDK command
  # line tools. This keg is never linked: consume it through its `opt_prefix`.
  keg_only "it is a component of `ohos-sdk`"

  depends_on "unzip" => :build

  def install
    cd "ohos" do
      Dir.glob("native-*.zip").each do |zip_file|
        system "unzip", "-q", zip_file
      end
    end

    # This formula packages one component of the SDK, so the content of the
    # `native` directory lands at the root of the keg: the prefix of this
    # formula is the SDK `native` directory.
    prefix.install (buildpath/"ohos/native").children
    llvm_bin_path = prefix/"llvm/bin"

    # Workaround for symbolic link materialization in official packages
    # to prevent Homebrew bottle size bloating.
    ln_map = {
      "clang"          => "clang-15",
      "clang++"        => "clang-15",
      "clang-cl"       => "clang-15",
      "clang-cpp"      => "clang-15",
      "ld64.lld"       => "lld",
      "ld.lld"         => "lld",
      "lld-link"       => "lld",
      "llvm-addr2line" => "llvm-symbolizer",
      "llvm-lib"       => "llvm-ar",
      "llvm-ranlib"    => "llvm-ar",
      "llvm-readelf"   => "llvm-readobj",
      "llvm-strip"     => "llvm-objcopy",
    }
    cd llvm_bin_path do
      ln_map.each do |link, target|
        rm link
        ln_s target, link
      end
    end

    # Replace ld.lld symlink with a wrapper script to enable default linker signing.
    # Ref: https://gitcode.com/openharmony/third_party_llvm-project/pull/882
    wrapper_content = <<~SH
      #!/bin/sh
      exec -a "$0" #{llvm_bin_path}/lld --code-sign "$@"
    SH
    rm llvm_bin_path/"ld.lld"
    (llvm_bin_path/"ld.lld").write wrapper_content
    chmod 0755, llvm_bin_path/"ld.lld"
  end

  test do
    assert_path_exists prefix/"sysroot/usr/lib"
    assert_path_exists prefix/"llvm/include/libcxx-ohos/include/c++/v1"
    assert_path_exists prefix/"build/cmake/ohos.toolchain.cmake"

    (testpath/"test-c.c").write <<~EOF
      #include <stdio.h>
      int main(void)
      {
          printf("Hello, World!\\n");
          return 0;
      }
    EOF
    system prefix/"llvm/bin/clang", "test-c.c", "-o", "test-c"
    assert_equal "Hello, World!", shell_output("./test-c").chomp

    (testpath/"test-cpp.cpp").write <<~EOF
      #include <iostream>
      int main()
      {
          std::cout << "Hello, World!\\n" << std::endl;
          return 0;
      }
    EOF
    system prefix/"llvm/bin/clang++", "test-cpp.cpp", "-o", "test-cpp"
    assert_equal "Hello, World!", shell_output("./test-cpp").strip
  end
end
