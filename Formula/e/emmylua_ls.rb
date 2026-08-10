class EmmyluaLs < Formula
  desc "Lua Language Server"
  homepage "https://github.com/EmmyLuaLs/emmylua-analyzer-rust"
  # The project name is `emmylua-analyzer-rust`, but it contains several crates, not all of which we install.
  url "https://github.com/EmmyLuaLs/emmylua-analyzer-rust/archive/refs/tags/0.25.0.tar.gz"
  sha256 "dc58e6b3f268a9abed01c7fdab64934a45c6fbdcfcdfe703d7c4cddb601ada1b"
  license "MIT"
  head "https://github.com/EmmyLuaLs/emmylua-analyzer-rust.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a8a1e906b4d83eac425d76ee4eae22957744d5a1c6c1f7610a492d0dc3ed784b"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/emmylua_ls")
    system "cargo", "install", *std_cargo_args(path: "crates/emmylua_doc_cli")
    system "cargo", "install", *std_cargo_args(path: "crates/emmylua_check")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/emmylua_ls --version")

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

    Open3.popen3(bin/"emmylua_ls") do |stdin, stdout|
      stdin.write "Content-Length: #{json.size}\r\n\r\n#{json}"
      sleep 3
      assert_match(/^Content-Length: \d+/i, stdout.readline)
    end
  end
end
