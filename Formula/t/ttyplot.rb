class Ttyplot < Formula
  desc "Realtime plotting utility for terminal with data input from stdin"
  homepage "https://github.com/tenox7/ttyplot"
  url "https://github.com/tenox7/ttyplot/archive/refs/tags/1.7.6.tar.gz"
  sha256 "37347a11899c5bfdb5f15fd69766fc5bdfdcb434aa82ae3e9dd10095c3266675"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2f72385946f7da44c737d1608b0dd088187240635b823c0f4048e7ff858c4ffb"
  end

  depends_on "pkgconf" => :build
  uses_from_macos "ncurses"

  def install
    system "make"
    bin.install "ttyplot"
  end

  test do
    # `ttyplot` writes directly to the TTY, and doesn't stop even when stdin is closed.
    assert_match "unit displayed beside vertical bar", shell_output("#{bin}/ttyplot -h")
  end
end
