class Diffutils < Formula
  desc "File comparison utilities"
  homepage "https://www.gnu.org/software/diffutils/"
  url "https://ftpmirror.gnu.org/gnu/diffutils/diffutils-3.12.tar.xz"
  mirror "https://ftp.gnu.org/gnu/diffutils/diffutils-3.12.tar.xz"
  sha256 "7c8b7f9fc8609141fdea9cece85249d308624391ff61dedaf528fcb337727dfd"
  license "GPL-3.0-or-later"
  revision 1
  compatibility_version 1

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "93b337ca1a957759292be29593277121350b0bf313207fa8d587a1365564a7f2"
  end

  def install
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"a").write "foo"
    (testpath/"b").write "foo"
    system bin/"diff", "a", "b"
  end
end
