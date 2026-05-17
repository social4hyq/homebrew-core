class Gotify < Formula
  desc "Command-line interface for pushing messages to gotify/server"
  homepage "https://github.com/gotify/cli"
  url "https://github.com/gotify/cli/archive/refs/tags/v2.3.2.tar.gz"
  sha256 "e3b798d89138fdbc355a66d0fc2ca96676591366460f72c8f38b81365bebe5ba"
  license "MIT"
  head "https://github.com/gotify/cli.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a8b66cfd8f291133b2cbd1a888e3a1073541ca5c93e945b157f435b136302a2a"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.Version=#{version} -X main.BuildDate=#{time.iso8601} -X main.Commit="
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gotify version")

    assert_match "token is not configured, run 'gotify init'",
      shell_output("#{bin}/gotify p test", 1)
  end
end
