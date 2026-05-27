class Clzip < Formula
  desc "C language version of lzip"
  homepage "https://www.nongnu.org/lzip/clzip.html"
  url "https://download.savannah.gnu.org/releases/lzip/clzip/clzip-1.16.tar.gz"
  mirror "https://download-mirror.savannah.gnu.org/releases/lzip/clzip/clzip-1.16.tar.gz"
  sha256 "f339a3a5dfc2220532dc36f937a7a58e3a3278b174f2815cc5615107e55966e4"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://download.savannah.gnu.org/releases/lzip/clzip/"
    regex(/href=.*?clzip[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3ae2696a2a481e4318572bc554a64ef70a910737e741b5da03989ac4accb8167"
  end

  def install
    system "./configure", *std_configure_args
    system "make", "install"
    pkgshare.install "testsuite"
  end

  test do
    cp_r pkgshare/"testsuite", testpath
    cd "testsuite" do
      ln_s bin/"clzip", "clzip"
      system "./check.sh"
    end
  end
end
