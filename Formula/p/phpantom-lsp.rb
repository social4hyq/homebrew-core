class PhpantomLsp < Formula
  desc "Fast PHP language server written in Rust"
  homepage "https://github.com/AJenbo/phpantom_lsp"
  url "https://github.com/AJenbo/phpantom_lsp/archive/refs/tags/0.9.0.tar.gz"
  sha256 "8b25c0fac83720759261a3b44bb3c95c2d55fb8cdadc051ea4b62fd0f3509ca9"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "53d0da55411c781e87887220ed2998926b85e6f6a22d99a27c66406b4c46414b"
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
