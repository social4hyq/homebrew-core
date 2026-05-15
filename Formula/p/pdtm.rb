class Pdtm < Formula
  desc "ProjectDiscovery's Open Source Tool Manager"
  homepage "https://github.com/projectdiscovery/pdtm"
  url "https://github.com/projectdiscovery/pdtm/archive/refs/tags/v0.1.3.tar.gz"
  sha256 "5aa5611e3a61df37a2e4030fd8742d4a1278840fe91c1e1fde129aab81f4fe45"
  license "MIT"
  head "https://github.com/projectdiscovery/pdtm.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1fae4fc7499371d750301e7afe06711c3193dd60e3b0295bf5784433c74ae5fd"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/pdtm"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/pdtm -version 2>&1")
    assert_match "#{testpath}/.pdtm/go/bin", shell_output("#{bin}/pdtm -show-path")
  end
end
