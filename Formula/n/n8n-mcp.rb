class N8nMcp < Formula
  desc "MCP for Claude Desktop, Claude Code, Windsurf, Cursor to build n8n workflows"
  homepage "https://www.n8n-mcp.com/"
  url "https://registry.npmjs.org/n8n-mcp/-/n8n-mcp-2.63.2.tgz"
  sha256 "dd99711a5f91b0d570b13c22fbeabe697ec615d55260898617e493132f91c121"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8a46b7d8e1b62609f928889bfdeaa056361c6c9f2c9aee71d845089444d10ef9"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    json = [
      %Q({"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"homebrew","version":"#{version}"}}}),
      '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}',
      '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}',
    ].join("\n") + "\n"

    output = pipe_output(bin/"n8n-mcp", json, 0)
    assert_match "\"name\":\"n8n-documentation-mcp\"", output
    assert_match "\"name\":\"search_nodes\"", output
  end
end
