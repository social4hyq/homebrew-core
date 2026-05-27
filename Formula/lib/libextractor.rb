class Libextractor < Formula
  desc "Library to extract meta data from files"
  homepage "https://www.gnu.org/software/libextractor/"
  url "https://ftpmirror.gnu.org/gnu/libextractor/libextractor-1.13.tar.gz"
  mirror "https://ftp.gnu.org/gnu/libextractor/libextractor-1.13.tar.gz"
  sha256 "bb8f312c51d202572243f113c6b62d8210301ab30cbaee604f9837d878cdf755"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "47dbbb28ef10a80f228af39c5b23c18bf6dfa1d3bfbb6ab813cbb971c3963434"
  end

  depends_on "pkgconf" => :build
  depends_on "libtool"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  conflicts_with "csound", because: "both install `extract` binaries"

  def install
    ENV.deparallelize

    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    fixture = test_fixtures("test.png")
    assert_match "Keywords for file", shell_output("#{bin}/extract #{fixture}")
  end
end
