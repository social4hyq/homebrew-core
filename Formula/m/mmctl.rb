class Mmctl < Formula
  desc "Remote CLI tool for Mattermost server"
  homepage "https://github.com/mattermost/mattermost"
  url "https://github.com/mattermost/mattermost/archive/refs/tags/v11.7.2.tar.gz"
  sha256 "edcc83075b768ed330a5f445a8b7109512fd5310427f5cc57e98d87a9f20b32b"
  license all_of: ["AGPL-3.0-only", "Apache-2.0"]
  head "https://github.com/mattermost/mattermost.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1eabdc4819c71db25a60a632b41c6e77e5e752e21073a296db9cba7f0a5ff429"
  end

  depends_on "go" => :build

  def install
    # remove non open source files
    rm_r("server/enterprise")
    rm Dir["server/cmd/mmctl/commands/compliance_export*"]

    ldflags = "-s -w -X github.com/mattermost/mattermost/server/v8/cmd/mmctl/commands.buildDate=#{time.iso8601}"
    system "make", "-C", "server", "setup-go-work"
    system "go", "build", "-C", "server", *std_go_args(ldflags:), "./cmd/mmctl"

    # Install shell completions
    generate_completions_from_executable(bin/"mmctl", "completion", shells: [:bash, :zsh])
  end

  test do
    output = pipe_output("#{bin}/mmctl help 2>&1")
    refute_match(/.*No such file or directory.*/, output)
    refute_match(/.*command not found.*/, output)
    assert_match(/.*mmctl \[command\].*/, output)
  end
end
