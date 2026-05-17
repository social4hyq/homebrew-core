class Unittest < Formula
  desc "C++ Unit Test Framework"
  homepage "https://unittest.red-bean.com/"
  url "https://unittest.red-bean.com/tar/unittest-0.50-62.tar.gz"
  sha256 "9586ef0149b6376da9b5f95a992c7ad1546254381808cddad1f03768974b165f"
  license "BSD-3-Clause"

  livecheck do
    url "https://unittest.red-bean.com/tar/"
    regex(/href=.*?unittest[._-]v?(\d+(?:[.-]\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "87bbde2afdd4e2af3d41dc089d581d14c8762f45a77629d37789bbe8e42436d5"
  end

  def install
    ENV.append "CXX", "-std=c++03"
    system "./configure", *std_configure_args
    system "make", "install"
    pkgshare.install "test/unittesttest"
  end

  test do
    system "#{pkgshare}/unittesttest"
  end
end
