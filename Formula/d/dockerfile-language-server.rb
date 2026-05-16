class DockerfileLanguageServer < Formula
  desc "Language server for Dockerfiles powered by Node, TypeScript, and VSCode"
  homepage "https://github.com/rcjsuen/dockerfile-language-server"
  url "https://registry.npmjs.org/dockerfile-language-server-nodejs/-/dockerfile-language-server-nodejs-0.15.0.tgz"
  sha256 "32ee93b98f43d8d60273019b7ed12a263593ba3a2308442ca7449d49676f480d"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5ba35bdf1c7555d08679252e124240cc96501f955d955706155772a176541f5a"
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

    Open3.popen3("#{bin}/docker-langserver", "--stdio") do |stdin, stdout|
      stdin.write "Content-Length: #{json.size}\r\n\r\n#{json}"
      sleep 3
      assert_match(/^Content-Length: \d+/i, stdout.readline)
    end
  end
end
