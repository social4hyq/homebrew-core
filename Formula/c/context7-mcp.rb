class Context7Mcp < Formula
  desc "Up-to-date code documentation for LLMs and AI code editors"
  homepage "https://github.com/upstash/context7"
  url "https://registry.npmjs.org/@upstash/context7-mcp/-/context7-mcp-4.0.2.tgz"
  sha256 "da9f9793678aa332cd9a74a9f118c638764ac69c34e95c1d139e7e7c15903071"
  license "MIT"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "35020cb738f03266b21113a941616b14f3f82a530fb7a8e10d5c4a9df088e46a"
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
    output = pipe_output(bin/"context7-mcp", json, 0)
    assert_match "resolve-library-id", output
  end
end
