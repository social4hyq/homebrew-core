class Naga < Formula
  desc "Terminal implementation of the Snake game"
  homepage "https://github.com/anayjoshi/naga/"
  url "https://github.com/anayjoshi/naga/archive/refs/tags/naga-v1.0.tar.gz"
  sha256 "7f56b03b34e2756b9688e120831ef4f5932cd89b477ad8b70b5bcc7c32f2f3b3"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "794f342b73b6afd1d1a21fda07e71f8c5e15b00eff57316231ec0c58a5d6bc02"
  end

  uses_from_macos "ncurses"

  conflicts_with "naga-cli", because: "both install `naga` binary"

  def install
    bin.mkpath
    system "make", "install", "INSTALL_PATH=#{bin}/naga"
  end

  test do
    assert_path_exists bin/"naga"
  end
end
