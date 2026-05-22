class Ttmath < Formula
  desc "Bignum library for C++"
  homepage "https://www.ttmath.org/"
  url "https://downloads.sourceforge.net/project/ttmath/ttmath/ttmath-0.9.3/ttmath-0.9.3-src.tar.gz"
  sha256 "4a9a7d1d377fc3907fb75facd4817ba6ac9d60bb4837584256467a54705c6fde"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6c9c25bfb2e75d3836aea886c4c160c06cfec77e82fac5c66de5201e98736527"
  end

  def install
    include.install "ttmath"
    pkgshare.install "samples"
  end

  test do
    cp_r pkgshare/"samples", testpath
    system "make", "-C", "samples", "all"
  end
end
