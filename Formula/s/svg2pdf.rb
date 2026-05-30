class Svg2pdf < Formula
  desc "Renders SVG images to a PDF file (using Cairo)"
  homepage "https://cairographics.org/"
  url "https://cairographics.org/snapshots/svg2pdf-0.1.3.tar.gz"
  sha256 "854a870722a9d7f6262881e304a0b5e08a1c61cecb16c23a8a2f42f2b6a9406b"
  license "HPND-sell-variant"
  revision 2

  livecheck do
    url "https://cairographics.org/snapshots/"
    regex(/href=.*?svg2pdf[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a107577ac8f6973c1cf9dec62ae5fc3ed57d76a70b8683bd674726fe7a5084ea"
  end

  depends_on "pkgconf" => :build
  depends_on "cairo"
  depends_on "libsvg-cairo"

  on_macos do
    depends_on "jpeg-turbo"
    depends_on "libpng"
    depends_on "libsvg"
  end

  resource("svg.svg") do
    url "https://raw.githubusercontent.com/mathiasbynens/small/master/svg.svg"
    sha256 "900fbe934249ad120004bd24adf66aad8817d89586273c0cc50e187bddebb601"
  end

  def install
    # Temporary Homebrew-specific work around for linker flag ordering problem in Ubuntu 16.04.
    # Remove after migration to 18.04.
    unless OS.mac?
      inreplace "src/Makefile.in", "$(svg2pdf_LDFLAGS) $(svg2pdf_OBJECTS)",
                                   "$(svg2pdf_OBJECTS) $(svg2pdf_LDFLAGS)"
    end

    system "./configure", "--mandir=#{man}", *std_configure_args
    system "make", "install"
  end

  test do
    resource("svg.svg").stage do
      system bin/"svg2pdf", "svg.svg", "test.pdf"
      assert_path_exists Pathname.pwd/"test.pdf"
    end
  end
end
