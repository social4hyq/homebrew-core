class Tsshd < Formula
  desc "UDP-based SSH server with roaming support"
  homepage "https://trzsz.github.io/tsshd"
  url "https://github.com/trzsz/tsshd/archive/refs/tags/v0.1.9.tar.gz"
  sha256 "fdf05a2323c8cc4ecef30e5258714d1651d80206f1bc0a5a88a45d716e82bb18"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "11182d803635f1808ac10c4256cebf366129119ef0b0b7519fc68f3c502f23da"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/tsshd"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tsshd -v")

    assert_match "KCP", shell_output("#{bin}/tsshd --kcp")
    assert_match "TCP", shell_output("#{bin}/tsshd --tcp")
    assert_match "QUIC", shell_output("#{bin}/tsshd --mtu 1200")
  end
end
