class DexterLsp < Formula
  desc "Elixir LSP optimized for large codebases"
  homepage "https://github.com/remoteoss/dexter"
  url "https://github.com/remoteoss/dexter/archive/refs/tags/v0.7.1.tar.gz"
  sha256 "94afaa0ce531ef9b47ab5f6857e91f691f558d8df0201a715826b87604595b6f"
  license "MIT"
  head "https://github.com/remoteoss/dexter.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "eb6f460f47483e964f098400c2a4ad6475ed1b399fdaa75bebffa22e2a29893f"
  end

  depends_on "go" => :build

  uses_from_macos "sqlite" => :build

  conflicts_with "dexter", because: "both install `dexter` binaries"

  def install
    ENV["CGO_ENABLED"] = "1" if OS.linux? && Hardware::CPU.arm?
    system "go", "build", "-buildvcs=false", *std_go_args(ldflags: "-s -w", output: bin/"dexter"), "./cmd"

    generate_completions_from_executable(bin/"dexter", "completion")
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

    Open3.popen3(bin/"dexter", "lsp") do |stdin, stdout|
      stdin.write "Content-Length: #{json.size}\r\n\r\n#{json}"
      assert_match(/^Content-Length: \d+/i, stdout.readline)
    end
  end
end
