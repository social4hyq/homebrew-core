class Libextractor < Formula
  desc "Library to extract meta data from files"
  homepage "https://www.gnu.org/software/libextractor/"
  url "https://ftpmirror.gnu.org/gnu/libextractor/libextractor-1.19.tar.gz"
  mirror "https://ftp.gnu.org/gnu/libextractor/libextractor-1.19.tar.gz"
  sha256 "2d5b33cbdb21c88ae9360994d4e216627413ee9cb11b31b033c2d0cf42ef2700"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b5c6c5b81f8c31a3f573b129a986a929a34454c7380df6c27712a78c6928820d"
  end

  depends_on "pkgconf" => :build
  depends_on "libtool"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  conflicts_with "csound", because: "both install `extract` binaries"

  def install
    ENV.deparallelize

    # macOS defines ntohll as a macro, clashing with the local definition
    inreplace "src/plugins/qt_extractor.c",
              "static uint64_t\nntohll (uint64_t n)",
              "#undef ntohll\n\\0"

    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    fixture = test_fixtures("test.png")
    assert_match "Keywords for file", shell_output("#{bin}/extract #{fixture}")
  end
end
