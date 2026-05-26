class Meek < Formula
  desc "Blocking-resistant pluggable transport for Tor"
  homepage "https://www.torproject.org"
  url "https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/meek/-/archive/v0.38.0/meek-v0.38.0.tar.gz"
  sha256 "63e8aef2828e7d0cc1dc5823fe82f9ae1e59cfc8c8dc118faab0a673c51ff257"
  license "CC0-1.0"
  head "https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/meek.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "74d0581d3bf7160a3b68d8da88fde7f5d0e263ed9389c2fd96311df885d9faa1"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(output: bin/"meek-client"), "./meek-client"
    system "go", "build", *std_go_args(output: bin/"meek-server"), "./meek-server"
    man1.install "doc/meek-client.1"
    man1.install "doc/meek-server.1"
  end

  test do
    assert_match "ENV-ERROR no TOR_PT_MANAGED_TRANSPORT_VER", shell_output("#{bin}/meek-client 2>/dev/null", 1)
    assert_match "ENV-ERROR no TOR_PT_MANAGED_TRANSPORT_VER", shell_output("#{bin}/meek-server 2>/dev/null", 1)
  end
end
