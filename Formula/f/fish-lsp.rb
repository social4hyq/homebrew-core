class FishLsp < Formula
  desc "LSP implementation for the fish shell language"
  homepage "https://www.fish-lsp.dev"
  url "https://registry.npmjs.org/fish-lsp/-/fish-lsp-1.1.3.tgz"
  sha256 "1579b9ff599a46fd9d1c276eec1b6d67dcc5cd45cb6637d776e7912794f2fa55"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "83f440a64ff420b6c0ded222fc221a5bc8f18eb26ae8fc981cfae195019c61f7"
  end

  depends_on "fish" => [:build, :test]
  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    man1.install "man/fish-lsp.1"
    generate_completions_from_executable(bin/"fish-lsp", "complete", shells: [:fish])
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
    output = pipe_output("#{bin}/fish-lsp start", input)
    assert_match(/^Content-Length: \d+/i, output)
  end
end
