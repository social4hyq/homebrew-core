class Icu4cAT77 < Formula
  desc "C/C++ and Java libraries for Unicode and globalization"
  homepage "https://icu.unicode.org/home"
  url "https://github.com/unicode-org/icu/releases/download/release-77-1/icu4c-77_1-src.tgz"
  version "77.1"
  sha256 "588e431f77327c39031ffbb8843c0e3bc122c211374485fa87dc5f3faff24061"
  license "ICU"
  revision 2

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1185206c7ffa428300b479e1cd5da9b540d4f9b8bb6969cb444a3be8866ffe0b"
  end

  keg_only :versioned_formula

  # Disable date set 1 year after ICU 78.1 release
  disable! date: "2026-10-30", because: :versioned_formula

  def install
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
