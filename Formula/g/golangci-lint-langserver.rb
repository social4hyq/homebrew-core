class GolangciLintLangserver < Formula
  desc "Language server for `golangci-lint`"
  homepage "https://github.com/nametake/golangci-lint-langserver"
  url "https://github.com/nametake/golangci-lint-langserver/archive/refs/tags/v0.0.12.tar.gz"
  sha256 "bdda9b1138f0a6cbfec0b2a93ef64111410bf16a82583c659e1b57f11ed93936"
  license "MIT"
  head "https://github.com/nametake/golangci-lint-langserver.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0dbf6550636dd379fd0d62c57eca27f36820cd148f85648058b40f1f1be7406f"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
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
    output = pipe_output(bin/"golangci-lint-langserver", input)
    assert_match(/^Content-Length: \d+/i, output)
  end
end
