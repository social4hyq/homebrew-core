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
  # llvm@21 的 lld 运行时依赖 libxml2/zlib;显式声明让 superenv 注入库路径。
  depends_on "libxml2" => :build
  depends_on "zlib"    => :build

  # bottle: 验证版先 build-from-source。出 bottle 时取消注释 + 重编填 sha256。
  # bottle do
  #   root_url "https://github.com/social4hyq/homebrew-core/releases/download/icu4c@78-v78.3"
  #   sha256 cellar: :any_skip_relocation, arm64_ohos: "0000000000000000000000000000000000000000000000000000000000000000"
  # end

  keg_only :shadowed_by_macos, "macOS provides libicucore.dylib (but nothing else)"

  def install
    odie "Major version bumps need a new formula!" if version.major.to_s != name[/@(\d+)$/, 1]

    clang = Formula["llvm@21"].opt_bin/"clang"
    clangxx = Formula["llvm@21"].opt_bin/"clang++"
    libxml2_lib = Formula["libxml2"].opt_lib.to_s
    zlib_lib    = Formula["zlib"].opt_lib.to_s
    ENV.prepend_path "LD_LIBRARY_PATH", libxml2_lib
    ENV.prepend_path "LD_LIBRARY_PATH", zlib_lib

    # ICU 的 config.guess 不识别 HarmonyOS(uname -s 返回 "HarmonyOS HongMeng Kernel"),
    # 参照 llvm@21.rb 的 patch_config_guess:替换为返回 aarch64-linux-ohos 的桩。
    cg = buildpath/"source/config.guess"
    if cg.exist? && !cg.read(64)&.include?("Stubbed for HarmonyOS")
      FileUtils.cp(cg, "#{cg}.orig")
      # brew 的 Pathname#write 拒绝覆盖;用 File.write 绕过。
      File.write(cg, "#!/bin/sh\necho aarch64-linux-ohos\n")
      cg.chmod 0755
    end

    # ── Phase 1: 原生构建 ICU 数据工具(icupkg/gencmn/pkgdata) ──
    # 不加 --target:llvm@21 默认 target=aarch64-unknown-linux-ohos,
    # 产出能在 OHOS 上执行的原生工具(Phase 2 构建期调用它们生成 data)。
    # 用 --host=gnu 触发交叉模式跳过运行测试程序(不签名无法执行)。
    # 真正的 target ABI 由编译器默认值控制,不与 --host 绑定。
    native_prefix = buildpath/"native"
    cd "source" do
      # Phase 1 是原生构建(无 --host),测试程序需能在设备上执行。
      # OHOS 开发模式下 unsigned ELF 可执行;--build=ohos 跳过 config.guess。
      system "./configure", *%w[--disable-samples --disable-tests --enable-static --with-library-bits=64],
             "--build=aarch64-linux-ohos", "--prefix=#{native_prefix}",
             "CC=#{clang}", "CXX=#{clangxx}",
             "CFLAGS=-O2", "CXXFLAGS=-O2 -stdlib=libc++",
             # -Wl,--code-sign:lld 签名,确保 Phase 2 调工具时可执行
             "LDFLAGS=-stdlib=libc++ -Wl,--code-sign"
      system "make", "-j", ENV.make_jobs.to_s
      system "make", "install"
    end

    # ── Phase 2: OHOS target 构建(用 llvm@21 + --target=ohos) ──
    # 显式 --target=aarch64-linux-ohos 确保产出的 .a 用 __h ABI(llvm@21 的 libc++)。
    # --with-cross-build 指向 Phase 1 的原生 build 目录(需 config/icucross.mk + 可执行工具)。
    ENV["TMPDIR"] = buildpath.to_s
    cd "source" do
      system "./configure", *%w[--disable-samples --disable-tests --enable-static],
             "--build=aarch64-linux-ohos", "--host=aarch64-linux-gnu",
             "--with-cross-build=#{native_prefix}", "--disable-tools",
             *std_configure_args,
             "CC=#{clang}", "CXX=#{clangxx}",
             "CFLAGS=-O2 -fPIC --target=aarch64-linux-ohos",
             "CXXFLAGS=-O2 -stdlib=libc++ -fPIC --target=aarch64-linux-ohos",
             "LDFLAGS=-stdlib=libc++ --target=aarch64-linux-ohos -Wl,--code-sign"
      system "make", "-j", ENV.make_jobs.to_s
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
