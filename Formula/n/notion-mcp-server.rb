class NotionMcpServer < Formula
  desc "MCP Server for Notion"
  homepage "https://github.com/makenotion/notion-mcp-server"
  url "https://registry.npmjs.org/@notionhq/notion-mcp-server/-/notion-mcp-server-2.4.1.tgz"
  sha256 "3ed924378048bcc28af97a2b22c505002c34b86e9e8d67664a0678fa7a312d8d"
  license "MIT"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "983dc934621bb3661e8f698cc701e65cf5f6487c66361e3fc1b78765a8636bae"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    json = <<~JSON
      {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26"}}
      {"jsonrpc":"2.0","id":2,"method":"tools/list"}
    JSON

    assert_match "Identifier for a Notion data source", pipe_output(bin/"notion-mcp-server", json, 0)
  end
end
