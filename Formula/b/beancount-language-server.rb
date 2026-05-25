class BeancountLanguageServer < Formula
  desc "Language server for beancount files"
  homepage "https://github.com/polarmutex/beancount-language-server"
  url "https://github.com/polarmutex/beancount-language-server/archive/refs/tags/1.9.2.tar.gz"
  sha256 "f2673b169e4d9fbb1cba4f47d8d90452023fb19921fda5565375ec9020317498"
  license "MIT"
  head "https://github.com/polarmutex/beancount-language-server.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "49829bb4e3f5c3aefd56b250aa0cee6d8f017192c29cf54f898e8a188ff0e729"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/lsp")
  end

  test do
    require "open3"

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

    Open3.popen3(bin/"beancount-language-server", "--stdio") do |stdin, stdout|
      stdin.write "Content-Length: #{json.size}\r\n\r\n#{json}"
      assert_match(/^Content-Length: \d+/i, stdout.readline)
    end

    assert_match version.to_s, shell_output("#{bin}/beancount-language-server --version")
  end
end
