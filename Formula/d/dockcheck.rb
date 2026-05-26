class Dockcheck < Formula
  desc "CLI tool to automate docker image updates"
  homepage "https://github.com/mag37/dockcheck"
  url "https://github.com/mag37/dockcheck/archive/refs/tags/v0.7.8.tar.gz"
  sha256 "b30c9151bb1672108562ab91cf947bce437d622098c13c4d00a519022e13fc71"
  license "GPL-3.0-only"
  head "https://github.com/mag37/dockcheck.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5c122c8f9f33d245ecdb86aefe0eb573ea66e5695a755d84fc5d69afdfe9fd15"
  end

  depends_on "regclient"

  uses_from_macos "jq", since: :sequoia

  def install
    bin.install "dockcheck.sh" => "dockcheck"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dockcheck -v")

    output = shell_output("#{bin}/dockcheck 2>&1", 1)
    assert_match "user does not have permissions to the docker socket", output
  end
end
