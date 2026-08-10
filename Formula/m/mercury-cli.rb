class MercuryCli < Formula
  desc "CLI interface for Mercury banking"
  homepage "https://github.com/MercuryTechnologies/mercury-cli"
  url "https://github.com/MercuryTechnologies/mercury-cli/archive/refs/tags/v0.11.6.tar.gz"
  sha256 "a25a631909eebaa5efa50475aa65898f470189854c6fb05d495bb9c582b3a6ea"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b72eef067e80a9f1d60ddd1512506badf9ac5819b47e760a166fa426d45cc23e"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"mercury"), "./cmd/mercury"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mercury --version")
    assert_match "Authentication Status", shell_output("#{bin}/mercury status 2>&1")
    assert_match "Your dedication to modern banking has not gone unnoticed", pipe_output("#{bin}/mercury hat 2>&1")
  end
end
