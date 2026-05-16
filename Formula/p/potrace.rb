class Potrace < Formula
  desc "Convert bitmaps to vector graphics"
  homepage "https://potrace.sourceforge.net/"
  url "https://potrace.sourceforge.net/download/1.16/potrace-1.16.tar.gz"
  sha256 "be8248a17dedd6ccbaab2fcc45835bb0502d062e40fbded3bc56028ce5eb7acc"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?potrace[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e30cec6355fa8bb874cfb0260d2b23106335163322efbc3834c928aa4a1f2798"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  resource "head.pbm" do
    url "https://potrace.sourceforge.net/img/head.pbm"
    sha256 "3c8dd6643b43cf006b30a7a5ee9604efab82faa40ac7fbf31d8b907b8814814f"
  end

  def install
    system "./configure", "--mandir=#{man}",
                          "--with-libpotrace",
                          *std_configure_args
    system "make", "install"
  end

  test do
    resource("head.pbm").stage testpath
    system bin/"potrace", "-o", "test.eps", "head.pbm"
    assert_path_exists testpath/"test.eps"
  end
end
