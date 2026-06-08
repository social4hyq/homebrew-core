class Icu4cAT76 < Formula
  desc "C/C++ and Java libraries for Unicode and globalization"
  homepage "https://icu.unicode.org/home"
  url "https://github.com/unicode-org/icu/releases/download/release-76-1/icu4c-76_1-src.tgz"
  version "76.1"
  sha256 "dfacb46bfe4747410472ce3e1144bf28a102feeaa4e3875bac9b4c6cf30f4f3e"
  license "ICU"
  revision 3

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4cb4523a894a490f987f3e705a46d729cb2c3a9de7117513a2731198ea2b6614"
  end

  keg_only :versioned_formula

  # Deprecated with ICU 77.1 release
  deprecate! date: "2025-03-29", because: :versioned_formula
  disable! date: "2026-03-29", because: :versioned_formula

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
