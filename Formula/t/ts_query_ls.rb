class TsQueryLs < Formula
  desc "LSP implementation for Tree-sitter's query files"
  homepage "https://github.com/ribru17/ts_query_ls"
  url "https://github.com/ribru17/ts_query_ls/archive/refs/tags/v3.16.0.tar.gz"
  sha256 "2e145fdb7fef06ac73a77a377d5e879af41c8e7194928abb7c2536263b2f519d"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "665eba4beef15b52b2f1d041b48cc53f927c0010af6de25977152da69254abe4"
  end

  depends_on "cmake" => :build
  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    input = <<~JSON
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

    output = /Content-Length: \d+\r\n\r\n/

    assert_match output, pipe_output(bin/"ts_query_ls", input, 0)
  end
end
