class WoodpeckerCli < Formula
  desc "CLI client for the Woodpecker Continuous Integration server"
  homepage "https://woodpecker-ci.org/"
  url "https://github.com/woodpecker-ci/woodpecker/archive/refs/tags/v3.14.1.tar.gz"
  sha256 "f84115ea73513b9728570c90d85fef09ac07879232e2f1741f766a9368a2a954"
  license "Apache-2.0"
  head "https://github.com/woodpecker-ci/woodpecker.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ad13e8a938ed9f4112082135274be58d70f37203c683240c7b69327366382898"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X go.woodpecker-ci.org/woodpecker/v#{version.major}/version.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/cli"
    generate_completions_from_executable(bin/"woodpecker-cli", "completion")
    # woodpecker-cli expects "pwsh", not "powershell" so we use the custom shell_parameter_format
    (pwsh_completion/"woodpecker-cli").write Utils.safe_popen_read(
      { "SHELL" => "pwsh" }, bin/"woodpecker-cli", "completion", "pwsh"
    )
  end

  test do
    output = shell_output("#{bin}/woodpecker-cli info 2>&1", 1)
    assert_match "woodpecker-cli is not set up", output

    output = shell_output("#{bin}/woodpecker-cli lint 2>&1", 1)
    assert_match "could not detect pipeline config", output

    assert_match version.to_s, shell_output("#{bin}/woodpecker-cli --version")
  end
end
