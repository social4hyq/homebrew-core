class OhosSdk < Formula
  desc "OpenHarmony SDK"
  homepage "https://gitcode.com/openharmony"
  url "https://cidownload.openharmony.cn/version/Master_Version/ohos-sdk-public_ohos/20260330_020501/version-Master_Version-ohos-sdk-public_ohos-20260330_020501-ohos-sdk-public_ohos.tar.gz"
  version "26.0.0.18" # Keep the version number consistent with the one in the zip package name.
  sha256 "191094c9efcc4c0a6874aadaec5a1bf8b16f09f60c8f34a828d4ab0007356248"
  license "Apache-2.0"
  revision 2

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2ba30fbe170387d947066287102f0aec7d26c49b6eadee50d925ae9969d30905"
  end

  depends_on "unzip" => :build

  conflicts_with "llvm", because: "both install `clang` binaries"
  conflicts_with "llvm@22", because: "both install `clang` binaries"
  conflicts_with "llvm@21", because: "both install `clang` binaries"

  def install
    cd "ohos" do
      Dir.glob("*.zip").each do |zip_file|
        system "unzip", "-q", zip_file
        rm zip_file
      end
    end

    prefix.install Dir["ohos/*"]
    llvm_bin_path = prefix/"native/llvm/bin"
    bin.mkpath

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

    # Clang fails to resolve sysroot when invoked via symlinks;
    # using a wrapper script to ensure correct path resolution.
    bin.write_exec_script llvm_bin_path/"clang"
    bin.write_exec_script llvm_bin_path/"clang++"
    bin.write_exec_script llvm_bin_path/"clang-cpp"

    # Symlink other binaries in llvm/bin and toolchains directly as they don't require wrappers.
    # Only specific commands are symlinked to PATH to avoid naming conflicts with system tools.
    whitelist = %w[
      ld.lld
      lldb
      llvm-addr2line
      llvm-ar
      llvm-as
      llvm-cfi-verify
      llvm-config
      llvm-cov
      llvm-cxxfilt
      llvm-dis
      llvm-dwarfdump
      llvm-dwp
      llvm-lib
      llvm-link
      llvm-modextract
      llvm-nm
      llvm-objcopy
      llvm-objdump
      llvm-profdata
      llvm-ranlib
      llvm-rc
      llvm-readelf
      llvm-readobj
      llvm-size
      llvm-strings
      llvm-strip
      llvm-symbolizer
    ]
    whitelist.each do |file|
      ln_s "#{llvm_bin_path}/#{file}", bin/file
    end

    sdk_toolchains = prefix/"toolchains"
    %w[
      ark_disasm
      hdc
      rawheap_translator
      restool
      syscap_tool
    ].each do |tool|
      ln_s sdk_toolchains/tool, bin/tool
    end

    %w[
      binary-sign-tool
      hap-sign-tool
      ohos_packing_tool
    ].each do |tool|
      ln_s sdk_toolchains/"lib"/tool, bin/tool
    end
  end

  test do
    assert_path_exists prefix/"ets"
    assert_path_exists prefix/"js"
    assert_path_exists prefix/"native"
    assert_path_exists prefix/"previewer"
    assert_path_exists prefix/"toolchains"

    (testpath/"test-c.c").write <<~EOF
      #include <stdio.h>
      int main(void)
      {
          printf("Hello, World!\\n");
          return 0;
      }
    EOF
    system bin/"clang", "test-c.c", "-o", "test-c"
    system "./test-c"

    (testpath/"test-cpp.cpp").write <<~EOF
      #include <iostream>
      int main()
      {
          std::cout << "Hello, World!\\n" << std::endl;
          return 0;
      }
    EOF
    system bin/"clang++", "test-cpp.cpp", "-o", "test-cpp"
    system "./test-cpp"

    system bin/"binary-sign-tool", "sign",
      "-inFile", "./test-cpp",
      "-outFile", "./test-cpp",
      "-selfSign", "1"
  end
end
