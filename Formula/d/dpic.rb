class Dpic < Formula
  desc "Implementation of the GNU pic \"little language\""
  homepage "https://ece.uwaterloo.ca/~aplevich/dpic/"
  url "https://ece.uwaterloo.ca/~aplevich/dpic/dpic-2025.08.01.tar.gz"
  sha256 "0f38f5c1e91518826cb2c6e95624b390d1808efadc0402f83911512f0ce726c3"
  license "BSD-2-Clause"

  livecheck do
    url :homepage
    regex(/href=["']?dpic[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "59cb1ee572155ae62fb23b66fb6af23c5286f94008cfd576a5c09fd21b673c89"
  end

  def install
    system "./configure", *std_configure_args
    system "make"
    bin.install "dpic"
  end

  test do
    (testpath/"test.pic").write <<~EOS
      .PS
      down; box; arrow; ellipse; arrow; circle
      move down
      left; box; arrow; ellipse; arrow; circle
      [ right; box; arrow; circle; arrow down from last circle.s; ellipse ] \
        with .w at (last circle,1st ellipse)
      .PE
    EOS
    system bin/"dpic", "-g", "test.pic"
  end
end
