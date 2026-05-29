class NotionMcpServer < Formula
  desc "MCP Server for Notion"
  homepage "https://github.com/makenotion/notion-mcp-server"
  url "https://registry.npmjs.org/@notionhq/notion-mcp-server/-/notion-mcp-server-2.2.1.tgz"
  sha256 "b856cea9d403166f4a46049b0e011865bd90272fd9bee14e22cf1cc6f06c0b70"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "46c21e3ab227a21f9d6375f6918a564f2257525e29207f3df0ee2b719a77b19f"
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
