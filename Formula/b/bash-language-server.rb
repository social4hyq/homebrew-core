class BashLanguageServer < Formula
  desc "Language Server for Bash"
  homepage "https://github.com/bash-lsp/bash-language-server"
  url "https://registry.npmjs.org/bash-language-server/-/bash-language-server-5.8.0.tgz"
  sha256 "bcdedf2b48dfcab6e877523134e87f8d2e0ede8ff03d302786c32ec9a97f35ab"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "033a69b02978cac4edeb6e13dc5b19b77b57046ef94193135341756ead9c5c49"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    json = <<~JSON
      {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
          "rootUri": null,
          "capabilities": {}
        }
      }
    JSON
    input = "Content-Length: #{json.size}\r\n\r\n#{json}"
    output = pipe_output("#{bin}/bash-language-server start", input, 0)
    assert_match(/^Content-Length: \d+/i, output)
  end
end
