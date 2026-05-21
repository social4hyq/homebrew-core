class SlackMcpServer < Formula
  desc "Powerful MCP Slack Server with multiple transports and smart history fetch logic"
  homepage "https://github.com/korotovsky/slack-mcp-server"
  url "https://github.com/korotovsky/slack-mcp-server/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "815b7852124b33823bd33f9d505149b876cc3a220259e379687304a19957f916"
  license "MIT"
  head "https://github.com/korotovsky/slack-mcp-server.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c296ebc53a47e72abd11d6b26ef9d757def456cc0374416cc44feea0aa610614"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/slack-mcp-server"
  end

  test do
    # User OAuth token
    ENV["SLACK_MCP_XOXP_TOKEN"] = "xoxp-test-token"
    output = shell_output("#{bin}/slack-mcp-server 2>&1", 1)
    assert_match(/Failed to create MCP Slack client|Authentication failed - check your Slack tokens/, output)
  end
end
