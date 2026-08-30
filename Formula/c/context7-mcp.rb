class Context7Mcp < Formula
  desc "Up-to-date code documentation for LLMs and AI code editors"
  homepage "https://github.com/upstash/context7"
  url "https://registry.npmjs.org/@upstash/context7-mcp/-/context7-mcp-4.0.4.tgz"
  sha256 "40107e4f3c78c462efe46899c6c92439516dce75a0155c00b9a10b9966859a48"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "51854aaf0f94ae668c7055751a4191e19399c72b8e9bd9f2e80cea0ef9db76a0"
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
