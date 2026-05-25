class Tsshd < Formula
  desc "UDP-based SSH server with roaming support"
  homepage "https://trzsz.github.io/tsshd"
  url "https://github.com/trzsz/tsshd/archive/refs/tags/v0.1.8.tar.gz"
  sha256 "1d19f99a95f19933d8058df1209b421400eaca8c2bf2e045747c8f6c68887d56"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e4c58cc05076e986a59d0cc057e09564412878fb04a5db973e92e1f84fac35e9"
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
