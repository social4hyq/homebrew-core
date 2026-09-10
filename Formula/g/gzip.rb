class Gzip < Formula
  desc "Popular GNU data compression program"
  homepage "https://www.gnu.org/software/gzip/"
  url "https://ftpmirror.gnu.org/gnu/gzip/gzip-1.14.tar.gz"
  mirror "https://ftp.gnu.org/gnu/gzip/gzip-1.14.tar.gz"
  sha256 "613d6ea44f1248d7370c7ccdeee0dd0017a09e6c39de894b3c6f03f981191c6b"
  license "GPL-3.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0a2bcfe104e9336ca915f07a7b1284e1727605b2acb38dcb4984d34d5a37d3cf"
  end

  def install
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"foo").write "test"
    system bin/"gzip", "foo"
    system bin/"gzip", "-t", "foo.gz"
    assert_equal "test", shell_output("#{bin}/gunzip -c foo")
  end
end
