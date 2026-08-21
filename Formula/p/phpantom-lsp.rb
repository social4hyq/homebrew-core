class PhpantomLsp < Formula
  desc "Fast PHP language server written in Rust"
  homepage "https://github.com/AJenbo/phpantom_lsp"
  url "https://github.com/AJenbo/phpantom_lsp/archive/refs/tags/0.10.0.tar.gz"
  sha256 "20db6d1a0e709ada6beee420323c979a5245ba1949c88824f1cc4d624b31bec7"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c80a88c12c53cc0cdba336aa04760ef79e68e732682309911685c147aefacaab"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
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
    output = pipe_output("#{bin}/phpantom_lsp --stdio 2>&1", input, 0)
    assert_match(/^Content-Length: \d+/i, output)
  end
end
