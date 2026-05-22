class RustAnalyzer < Formula
  desc "Experimental Rust compiler front-end for IDEs"
  homepage "https://rust-analyzer.github.io/"
  url "https://github.com/rust-lang/rust-analyzer.git",
      tag:      "2026-05-18",
      revision: "ce81cf65580fb7a52d9f9a896092746356f39320"
  license any_of: ["Apache-2.0", "MIT"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0e12b754abbfb2434ef31e1db4f78cd12fd18d045c7e020188f288fc32dbaa31"
  end

  depends_on "rust" => :build

  def install
    cd "crates/rust-analyzer" do
      system "cargo", "install", "--bin", "rust-analyzer", *std_cargo_args
    end
  end

  def rpc(json)
    "Content-Length: #{json.size}\r\n" \
      "\r\n" \
      "#{json}"
  end

  test do
    input = rpc <<~JSON
      {
        "jsonrpc":"2.0",
        "id":1,
        "method":"initialize",
        "params": {
          "rootUri": "file:/dev/null",
          "capabilities": {}
        }
      }
    JSON

    input += rpc <<~JSON
      {
        "jsonrpc":"2.0",
        "method":"initialized",
        "params": {}
      }
    JSON

    input += rpc <<~JSON
      {
        "jsonrpc":"2.0",
        "id": 1,
        "method":"shutdown",
        "params": null
      }
    JSON

    input += rpc <<~JSON
      {
        "jsonrpc":"2.0",
        "method":"exit",
        "params": {}
      }
    JSON

    output = /Content-Length: \d+\r\n\r\n/

    assert_match output, pipe_output(bin/"rust-analyzer", input, 0)
  end
end
