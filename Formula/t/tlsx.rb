class Tlsx < Formula
  desc "Fast and configurable TLS grabber focused on TLS based data collection"
  homepage "https://github.com/projectdiscovery/tlsx"
  url "https://github.com/projectdiscovery/tlsx/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "c0aeb253d83f1c8ed261a135b19403caf46cee3066882056875a13d5b1a2a75a"
  license "MIT"
  head "https://github.com/projectdiscovery/tlsx.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e6d0b15a696dbcfa3b9a0a03989475aaba4ae5d49cbb9b77a990b4faa723c2a2"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/tlsx"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tlsx -version 2>&1")
    system bin/"tlsx", "-u", "expired.badssl.com:443", "-expired"
  end
end
