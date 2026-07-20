class PhpantomLsp < Formula
  desc "Fast PHP language server written in Rust"
  homepage "https://github.com/AJenbo/phpantom_lsp"
  url "https://github.com/AJenbo/phpantom_lsp/archive/refs/tags/0.9.0.tar.gz"
  sha256 "8b25c0fac83720759261a3b44bb3c95c2d55fb8cdadc051ea4b62fd0f3509ca9"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6853a56ea5cefcf8a4ebe053aa3b10a6ba8d39de3d4f7534c3cf1ff42ae2597b"
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
