class McpGet < Formula
  desc "CLI for discovering, installing, and managing MCP servers"
  homepage "https://github.com/michaellatman/mcp-get"
  url "https://registry.npmjs.org/@michaellatman/mcp-get/-/mcp-get-1.0.116.tgz"
  sha256 "9b1c5ab321d15bcf10cb1e27aacd55e428fd7f1fd4c4b3483dcddc4417389ce4"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dda506a5dace1bb33259826dd06a55e08280495ddb4b4baf422288a7ae971f2e"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match "No MCP servers are currently installed", shell_output("#{bin}/mcp-get installed")
  end
end
