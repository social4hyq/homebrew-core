class OhosSdk < Formula
  desc "OpenHarmony SDK"
  homepage "https://gitcode.com/openharmony"
  url "https://cidownload.openharmony.cn/version/Master_Version/ohos-sdk-public_ohos/20260330_020501/version-Master_Version-ohos-sdk-public_ohos-20260330_020501-ohos-sdk-public_ohos.tar.gz"
  version "26.0.0.18"
  sha256 "191094c9efcc4c0a6874aadaec5a1bf8b16f09f60c8f34a828d4ab0007356248"
  license "Apache-2.0"
  revision 3

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ef6753c7c4b2a3d760d17774564917ce06bcf632700412c792f51a9731e3d1ae"
  end

  # The SDK is distributed as one package per component, each of them packaged
  # by its own formula. Those formulae are keg-only, this one is the only entry
  # point of the SDK: it exposes the command line tools on PATH and keeps the
  # components reachable under a single prefix.
  depends_on "ohos-sdk-ets"
  depends_on "ohos-sdk-js"
  depends_on "ohos-sdk-native"
  depends_on "ohos-sdk-previewer"
  depends_on "ohos-sdk-toolchains"

  conflicts_with "llvm", because: "both install `clang` binaries"
  conflicts_with "llvm@22", because: "both install `clang` binaries"
  conflicts_with "llvm@21", because: "both install `clang` binaries"
  conflicts_with "lld", because: "both install `lld` binaries"
  conflicts_with "lld@22", because: "both install `lld` binaries"
  conflicts_with "lld@21", because: "both install `lld` binaries"

  def install
    # Symlink the components into this keg so that the SDK keeps the layout it
    # had when it was a single formula (`native/`, `toolchains/`, ...).
    %w[ets js native previewer toolchains].each do |component|
      ln_s formula_opt_prefix("ohos-sdk-#{component}"), prefix/component
    end

    llvm_bin_path = prefix/"native/llvm/bin"
    bin.mkpath

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
