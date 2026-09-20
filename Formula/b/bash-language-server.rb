class BashLanguageServer < Formula
  desc "Language Server for Bash"
  homepage "https://github.com/bash-lsp/bash-language-server"
  url "https://registry.npmjs.org/bash-language-server/-/bash-language-server-5.8.1.tgz"
  sha256 "2ae910de8c50f4ec148222bdc580c121f2c621bdacc1225716218ca700f8ec79"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "671dd87365f5654ba3e24d510041cdc1854cf89b6267e1968cd59c81fb02f599"
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
