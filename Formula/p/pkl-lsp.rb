class PklLsp < Formula
  desc "Language server for Pkl"
  homepage "https://pkl-lang.org/lsp/current/index.html"
  url "https://github.com/apple/pkl-lsp/releases/download/0.7.1/pkl-lsp-0.7.1.jar"
  sha256 "4e84450537c1b5e0eddf6f64fc93ae6f884ff45ee3ed4296b5c061e7a7c7f34e"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "77ed84aef307c72d7b3e54f9884c813a3590cecf52f640579d54ff5551633a43"
  end

  depends_on "openjdk"

  def install
    libexec.install "pkl-lsp-#{version}.jar" => "pkl-lsp.jar"
    bin.write_jar_script libexec/"pkl-lsp.jar", "pkl-lsp"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/pkl-lsp --version")

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

    Open3.popen3(bin/"pkl-lsp") do |stdin, stdout, _, w|
      stdin.write "Content-Length: #{json.size}\r\n\r\n#{json}"
      stdin.close
      sleep 1
      sleep 2 if OS.mac? && Hardware::CPU.intel?
      Process.kill("TERM", w.pid)
      assert_match(/^Content-Length: \d+/i, stdout.readline)
    end
  end
end
