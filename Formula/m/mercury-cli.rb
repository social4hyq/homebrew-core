class MercuryCli < Formula
  desc "CLI interface for Mercury banking"
  homepage "https://github.com/MercuryTechnologies/mercury-cli"
  url "https://github.com/MercuryTechnologies/mercury-cli/archive/refs/tags/v0.9.2.tar.gz"
  sha256 "df042ebd7f4acab549be14a781b64b9f16bf78ee60266a6b2c655ebbc8119b08"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "35cdc3939fb15333908e4a53960536cd30cbb129828aaca6320c321f1c96b0dd"
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
