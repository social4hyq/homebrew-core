class Vtsls < Formula
  desc "LSP wrapper for typescript extension of vscode"
  homepage "https://github.com/yioneko/vtsls"
  url "https://registry.npmjs.org/@vtsls/language-server/-/language-server-0.3.0.tgz"
  sha256 "f065ff01476d71395caad2647fb56539bb80131f37081767b2aeee8586cbc0c9"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6b7322ae7a3f4bcb988dd8514e6c0d7a008b4e044e6ff46208abebd488118795"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
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

    Open3.popen3(bin/"vtsls", "--stdio") do |stdin, stdout|
      stdin.write "Content-Length: #{json.size}\r\n\r\n#{json}"
      assert_match(/^Content-Length: \d+/i, stdout.readline)
    end
  end
end
