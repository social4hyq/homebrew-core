class McpRemote < Formula
  desc "Remote proxy for Model Context Protocol with OAuth support"
  homepage "https://github.com/geelen/mcp-remote"
  url "https://registry.npmjs.org/mcp-remote/-/mcp-remote-0.2.1.tgz"
  sha256 "a48bf3e7f46baa1273a0d11e3f9dfa1383042b40daab0b82633ae0414524ab24"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "45bb17debe5c58ab2ffc70475caf3e9ed35550869908424659dca583f3ddfd77"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match "Using transport strategy: http-first",
      shell_output("#{bin}/mcp-remote https://mcp.example.com/mcp 2>&1", 1)
  end
end
