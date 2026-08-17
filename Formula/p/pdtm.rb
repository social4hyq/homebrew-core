class Pdtm < Formula
  desc "ProjectDiscovery's Open Source Tool Manager"
  homepage "https://github.com/projectdiscovery/pdtm"
  url "https://github.com/projectdiscovery/pdtm/archive/refs/tags/v0.1.5.tar.gz"
  sha256 "13746a1da82961dcfc9d797206abd6ba75336879f2292228e92a2813000d1654"
  license "MIT"
  head "https://github.com/projectdiscovery/pdtm.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c0f81640a3c96b7998e64c0e9a27b9b6e5534461f1965ad6a232abb36136a37c"
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
