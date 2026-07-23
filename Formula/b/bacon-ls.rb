class BaconLs < Formula
  desc "Rust diagnostic provider based on Bacon"
  homepage "https://github.com/crisidev/bacon-ls"
  url "https://github.com/crisidev/bacon-ls/archive/refs/tags/0.30.0.tar.gz"
  sha256 "c26692de95e7f838aeee2353d8e10bd9b32fb1a97b10f63e31aad0fc05285d40"
  license "MIT"
  head "https://github.com/crisidev/bacon-ls.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5267398a54f268587db0b0c6cacc7ed827f5d543f15eb19ec49cc4a38d8744a2"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    require "open3"

    assert_match version.to_s, shell_output("#{bin}/bacon-ls --version")

    init_json = <<~JSON
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

    Open3.popen3(bin/"bacon-ls") do |stdin, stdout, _|
      stdin.write "Content-Length: #{init_json.bytesize}\r\n\r\n#{init_json}"
      stdin.close

      assert_match(/^Content-Length: \d+/i, stdout.read)
    end
  end
end
