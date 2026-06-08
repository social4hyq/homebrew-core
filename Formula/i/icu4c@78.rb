class Icu4cAT78 < Formula
  desc "C/C++ and Java libraries for Unicode and globalization"
  homepage "https://icu.unicode.org/home"
  url "https://github.com/unicode-org/icu/releases/download/release-78.3/icu4c-78.3-sources.tgz"
  sha256 "3a2e7a47604ba702f345878308e6fefeca612ee895cf4a5f222e7955fabfe0c0"
  license "ICU"
  revision 1
  compatibility_version 1

  # We allow the livecheck to detect new `icu4c` major versions in order to
  # automate version bumps. To make sure PRs are created correctly, we output
  # an error during installation to notify when a new formula is needed.
  livecheck do
    url :stable
    regex(/^release[._-]v?(\d+(?:[.-]\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag[regex, 1]&.tr("-", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "26927672131aebc8b50403cd7e872d60eadd98ae522c1402c8a8d6d65b84b61e"
  end

  keg_only :shadowed_by_macos, "macOS provides libicucore.dylib (but nothing else)"

  def install
    odie "Major version bumps need a new formula!" if version.major.to_s != name[/@(\d+)$/, 1]

    args = %w[
      --disable-samples
      --disable-tests
      --enable-static
      --with-library-bits=64
    ]

    cd "source" do
      system "./configure", *args, *std_configure_args
      system "make"
      system "make", "install"
    end

    inreplace [bin/"icu-config", *lib.glob("pkgconfig/icu-*.pc")], prefix, opt_prefix

    # libicudata.so built by ICU's pkgdata tool is a pure data file
    # wrapped in an ELF container, not a real shared library. The
    # HarmonyOS system loader rejects such data-only ELFs.  Re-link
    # the objects from libicudata.a into a proper shared library so
    # that the system recognises it and the pipeline signing step
    # can process it successfully.
    if (lib/"libicudata.a").exist?
      ohai "Re-linking libicudata.so as a real shared library"
      ver = version.major
      so_name = "libicudata.so.#{ver}"
      so_full = "libicudata.so.#{version}"

      tmpdir = Pathname.new(Dir.mktmpdir("icudata"))
      begin
        system "clang", "-shared", "-fPIC",
               "-o", tmpdir/so_full,
               "-Wl,--whole-archive", lib/"libicudata.a",
               "-Wl,--no-whole-archive",
               "-Wl,-soname=#{so_name}",
               "-Wl,--gc-sections"

        lib.install tmpdir/so_full
        lib.install_symlink so_full => so_name
        lib.install_symlink so_name => "libicudata.so"
      ensure
        tmpdir.rmtree if tmpdir.exist?
      end
    end
  end

  test do
    if File.exist? "/usr/share/dict/words"
      system bin/"gendict", "--uchars", "/usr/share/dict/words", "dict"
    else
      (testpath/"hello").write "hello\nworld\n"
      system bin/"gendict", "--uchars", "hello", "dict"
    end
  end
end
