class Icu4cAT78 < Formula
  desc "C/C++ and Java libraries for Unicode and globalization"
  homepage "https://icu.unicode.org/home"
  url "https://github.com/unicode-org/icu/releases/download/release-78.3/icu4c-78.3-sources.tgz"
  sha256 "3a2e7a47604ba702f345878308e6fefeca612ee895cf4a5f222e7955fabfe0c0"
  license "ICU"
  # This formula deviates from upstream because it requires a two-phase cross-compile
  # with OHOS-patched llvm@21 to align libc++ ABI (__h namespace). Upstream uses
  # system clang which produces incompatible ABI symbols.
  revision 1
  compatibility_version 1

  livecheck do
    url :stable
    regex(/icu4c[._-](\d+(?:\.\d+)+)[._-]sources/i)
  end

  # Built with the OHOS-patched llvm@21 so ICU's libc++ symbols land in the __1 namespace,
  # matching the libc++ ABI linked by bun / WebKit (eliminates the stale bottle B9nqe220107 tag).
  # When graduating to official core: icu4c@78 can use system clang; this validation version
  # is only for verifying ABI alignment.
  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/icu4c@78-v78.3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "98f5609d63c8202fbee0c179b81f7af964f72dea6e760f0c1b8e0d1c1ab29cee"
  end

  keg_only :shadowed_by_macos, "macOS provides libicucore.dylib (but nothing else)"

  depends_on "libxml2" => :build

  depends_on "llvm@21" => :build
  # llvm@21's lld has runtime dependencies on libxml2/zlib; declare them explicitly so
  # superenv injects the library paths.
  depends_on "zlib"    => :build

  # bottle: validation version uses build-from-source first. Uncomment when publishing the
  # bottle and re-build to fill in the sha256.

  def install
    odie "Major version bumps need a new formula!" if version.major.to_s != name[/@(\d+)$/, 1]

    clang = Formula["llvm@21"].opt_bin/"clang"
    clangxx = Formula["llvm@21"].opt_bin/"clang++"
    libxml2_lib = Formula["libxml2"].opt_lib.to_s
    zlib_lib    = Formula["zlib"].opt_lib.to_s
    ENV.prepend_path "LD_LIBRARY_PATH", libxml2_lib
    ENV.prepend_path "LD_LIBRARY_PATH", zlib_lib

    # ICU's config.guess does not recognize HarmonyOS (uname -s returns "HarmonyOS HongMeng Kernel");
    # mirror the patch_config_guess approach in llvm@21.rb: replace it with a stub that returns
    # aarch64-linux-ohos.
    cg = buildpath/"source/config.guess"
    if cg.exist? && !cg.read(64)&.include?("Stubbed for HarmonyOS")
      cp(cg, "#{cg}.orig")
      # brew's Pathname#write refuses to overwrite; use File.write to bypass it.
      File.write(cg, "#!/bin/sh\necho aarch64-linux-ohos\n")
      cg.chmod 0755
    end

    # ── Phase 1: native build of ICU data tools (icupkg/gencmn/pkgdata) ──
    # No --target added: llvm@21's default target is aarch64-unknown-linux-ohos,
    # producing native tools that can run on OHOS (Phase 2 invokes them at build time to generate data).
    # Use --host=gnu to trigger cross mode and skip running test programs (they cannot run without signing).
    # The real target ABI is controlled by the compiler defaults, not bound to --host.
    native_prefix = buildpath/"native"
    cd "source" do
      # Phase 1 is a native build (no --host), so test programs must be runnable on the device.
      # OHOS developer mode allows unsigned ELF to execute; --build=ohos skips config.guess.
      system "./configure", *%w[--disable-samples --disable-tests --enable-static --with-library-bits=64],
             "--build=aarch64-linux-ohos", "--prefix=#{native_prefix}",
             "CC=#{clang}", "CXX=#{clangxx}",
             "CFLAGS=-O2", "CXXFLAGS=-O2 -stdlib=libc++",
             # -Wl,--code-sign: lld signs the binary so the tools are executable when Phase 2 invokes them.
             "LDFLAGS=-stdlib=libc++ -Wl,--code-sign"
      system "make", "-j", ENV.make_jobs.to_s
      system "make", "install"
    end

    # ── Phase 2: OHOS target build (using llvm@21 + --target=ohos) ──
    # Explicit --target=aarch64-linux-ohos ensures the produced .a uses the __h ABI (llvm@21's libc++).
    # --with-cross-build points to Phase 1's native build dir (requires config/icucross.mk + runnable tools).
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

    # libicudata.so is a pure-data ELF, which the OHOS loader rejects. Re-link from the .a into a real .so
    # for dynamic linking scenarios (bun links statically; this step is
    # mainly for compatibility with other OHOS formulas).
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
        rm_r(tmpdir) if tmpdir.exist?
      end
    end
  end

  test do
    (testpath/"hello").write "hello\nworld\n"
    system bin/"gendict", "--uchars", "hello", "dict"
  end
end
