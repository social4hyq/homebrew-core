class VueLanguageServer < Formula
  desc "Vue.js language server"
  homepage "https://github.com/vuejs/language-tools"
  url "https://registry.npmjs.org/@vue/language-server/-/language-server-3.3.2.tgz"
  sha256 "c28fe6b0bfe91f416c10f369e91310f408d145a1e5a473dd7c86d5b1497b8b14"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "09990f30c97c583de629a5a7b7ac766d968e8916dbe6b7faa6702d4611d4432a"
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

    Open3.popen3(bin/"vue-language-server", "--stdio") do |stdin, stdout|
      stdin.write "Content-Length: #{json.size}\r\n\r\n#{json}"
      sleep 3
      assert_match(/^Content-Length: \d+/i, stdout.readline)
    end
  end
end
