class MercuryCli < Formula
  desc "CLI interface for Mercury banking"
  homepage "https://github.com/MercuryTechnologies/mercury-cli"
  url "https://github.com/MercuryTechnologies/mercury-cli/archive/refs/tags/v0.11.3.tar.gz"
  sha256 "d11d4aca5c0ff4baddf610580b6a8af145c1d6fe8711130f40056e15eae17d47"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0ba4cffae0175e0bafd113c17833b707fc40796997205c055873e1066ba36e1c"
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
