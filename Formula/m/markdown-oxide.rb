class MarkdownOxide < Formula
  desc "Personal Knowledge Management System for the LSP"
  homepage "https://oxide.md"
  url "https://github.com/Feel-ix-343/markdown-oxide/archive/refs/tags/v0.25.11.tar.gz"
  sha256 "274446b861ebbf3098dcb7e0a5d3135df88df34b16a2c128288f900391dfbf75"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6c49e64fc615c15532a0efcad81729c2404014eb932b0e99c4f4135a4f84f43b"
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
    assert_match(/^Content-Length: \d+/i,
      pipe_output(bin/"markdown-oxide", "Content-Length: #{json.size}\r\n\r\n#{json}"))
  end
end
