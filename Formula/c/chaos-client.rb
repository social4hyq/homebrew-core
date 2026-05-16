class ChaosClient < Formula
  desc "Client to communicate with Chaos DB API"
  homepage "https://chaos.projectdiscovery.io"
  url "https://github.com/projectdiscovery/chaos-client/archive/refs/tags/v0.5.2.tar.gz"
  sha256 "322f0c200887c2b0e6c412c70ad5de741a30e7687028966cfe26aa7534218369"
  license "MIT"
  head "https://github.com/projectdiscovery/chaos-client.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "267ee2bd0b6b718054bdea1410c0155ea439589fffcf2b10354e13174c56c028"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"chaos"), "./cmd/chaos"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/chaos -version 2>&1")

    assert_match "PDCP_API_KEY not specified", shell_output("#{bin}/chaos -d brew.sh 2>&1", 1)
  end
end
