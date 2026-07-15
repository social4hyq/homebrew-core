class JfrogCli < Formula
  desc "Command-line interface for JFrog products"
  homepage "https://docs.jfrog.com/integrations/docs/jfrog-cli"
  url "https://github.com/jfrog/jfrog-cli/archive/refs/tags/v2.115.0.tar.gz"
  sha256 "b2c9a4e4712b00dee30f35e0945c0460b0529ab0543d76a245da30da0be528c4"
  license "Apache-2.0"
  head "https://github.com/jfrog/jfrog-cli.git", branch: "master"

  # There can be a notable gap between when a version is tagged and a
  # corresponding release is created, so we check the "latest" release instead
  # of the Git tags.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fda6d875dc7e63ab29916319b1b8bafac81629d0de1baa29ecae655c7bdafb2a"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"jf")
    bin.install_symlink "jf" => "jfrog"

    generate_completions_from_executable(bin/"jf", "completion")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/jf -v")
    assert_match version.to_s, shell_output("#{bin}/jfrog -v")
    with_env(JFROG_CLI_REPORT_USAGE: "false", CI: "true") do
      assert_match "build name must be provided in order to generate build-info",
        shell_output("#{bin}/jf rt bp --dry-run --url=http://127.0.0.1 2>&1", 1)
    end
  end
end
