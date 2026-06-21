class Icu4cAT78 < Formula
  desc "C/C++ and Java libraries for Unicode and globalization"
  homepage "https://icu.unicode.org/home"
  url "https://github.com/unicode-org/icu/releases/download/release-78.3/icu4c-78.3-sources.tgz"
  sha256 "3a2e7a47604ba702f345878308e6fefeca612ee895cf4a5f222e7955fabfe0c0"
  license "ICU"
  revision 1
  compatibility_version 1

  # 用 OHOS 补丁版 llvm@21 编译,使 ICU 的 libc++ 符号落在 __1 namespace,
  # 与 bun / WebKit 链接的 libc++ ABI 一致(消除 stale bottle 的 B9nqe220107 标签)。
  # 毕业时:官方 core 的 icu4c@78 用系统 clang 即可;本验证版仅用于校验 ABI 对齐。
  depends_on "llvm@21" => :build

  bottle do
    root_url "https://github.com/social4hyq/homebrew-core/releases/download/icu4c@78-v78.3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0000000000000000000000000000000000000000000000000000000000000000"
  end

  keg_only :shadowed_by_macos, "macOS provides libicucore.dylib (but nothing else)"

  def install
    odie "Major version bumps need a new formula!" if version.major.to_s != name[/@(\d+)$/, 1]

    clang = Formula["llvm@21"].opt_bin/"clang"
    clangxx = Formula["llvm@21"].opt_bin/"clang++"

    args = %w[
      --disable-samples
      --disable-tests
      --enable-static
      --with-library-bits=64
    ]

    cd "source" do
      # config.guess 不识别 HarmonyOS,显式指定 build triple。
      system "./configure", *args, *std_configure_args,
             "CC=#{clang}", "CXX=#{clangxx}",
             "CFLAGS=-O2 -fPIC --target=aarch64-linux-ohos",
             "CXXFLAGS=-O2 -stdlib=libc++ -fPIC --target=aarch64-linux-ohos",
             "LDFLAGS=-stdlib=libc++ --target=aarch64-linux-ohos",
             "--build=aarch64-unknown-linux-musl"
      system "make"
      system "make", "install"
    end

    inreplace [bin/"icu-config", *lib.glob("pkgconfig/icu-*.pc")], prefix, opt_prefix

    # libicudata.so 是纯数据 ELF,OHOS loader 拒收。从 .a 重链成真正 .so,
    # 供动态链接场景使用(bun 静态链接,此步主要为与其他 OHOS formula 兼容)。
    if (lib/"libicudata.a").exist?
      ohai "Re-linking libicudata.so as a real shared library"
      ver = version.major
      so_name = "libicudata.so.#{ver}"
      so_full = "libicudata.so.#{version}"

      tmpdir = Pathname.new(Dir.mktmpdir("icudata"))
      begin
        system clang, "-shared", "-fPIC",
               "-o", tmpdir/so_full,
               "-Wl,--whole-archive", lib/"libicudata.a",
               "-Wl,--no-whole-archive",
               "-Wl,-soname=#{so_name}",
               "-Wl,--gc-sections",
               "--target=aarch64-linux-ohos"

        lib.install tmpdir/so_full
        lib.install_symlink so_full => so_name
        lib.install_symlink so_name => "libicudata.so"
      ensure
        tmpdir.rmtree if tmpdir.exist?
      end
    end
  end

  test do
    (testpath/"hello").write "hello\nworld\n"
    system bin/"gendict", "--uchars", "hello", "dict"
  end
end
