class Msieve < Formula
  desc "C library for factoring large integers"
  homepage "https://sourceforge.net/projects/msieve/"
  url "https://downloads.sourceforge.net/project/msieve/msieve/Msieve%20v1.53/msieve153_src.tar.gz"
  sha256 "c5fcbaaff266a43aa8bca55239d5b087d3e3f138d1a95d75b776c04ce4d93bb4"
  license :public_domain

  livecheck do
    url :stable
    regex(%r{url=.*?/Msieve%20v?(\d+(?:\.\d+)+)/}i)
  end

  no_autobump! because: :incompatible_version_format

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6f5dd8645a42a2947ddcbc3c5e0ad67ce8c6c847cf538f757694b1d272f85994"
  end

  depends_on "gmp"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    ENV.append "MACHINE_FLAGS", "-include sys/time.h"
    system "make", "all"
    bin.install "msieve"
  end

  test do
    assert_match "20\np1: 2\np1: 2\np1: 5", shell_output("#{bin}/msieve -q 20")
  end
end
