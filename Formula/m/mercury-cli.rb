class MercuryCli < Formula
  desc "CLI interface for Mercury banking"
  homepage "https://github.com/MercuryTechnologies/mercury-cli"
  url "https://github.com/MercuryTechnologies/mercury-cli/archive/refs/tags/v0.11.8.tar.gz"
  sha256 "954c4e088ea7d714abd215efeafc2161218bc5e5952ab8de30ae8701befcf801"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bfdd5ec3f94fb70d5b3be056012a990b97e5fc3b29621ecc8c7ab806deb50f71"
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
