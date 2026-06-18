class Lspmux < Formula
  desc "Share one language instance between multiple LSP clients to save resources"
  homepage "https://codeberg.org/p2502/lspmux"
  url "https://codeberg.org/p2502/lspmux/archive/v0.3.0.tar.gz"
  sha256 "92410dfcda4429e0463db91b67712da00fda5fa9fb5316174126e702eb988440"
  license "EUPL-1.2"
  head "https://codeberg.org/p2502/lspmux.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "156a36b9059d969f086f1f2e4a17b0f8d7d50f20d539bbaf43bb356c3082ef19"
  end

  depends_on "rust" => :build
  depends_on "rust-analyzer"

  def install
    system "cargo", "install", *std_cargo_args
  end

  service do
    run [opt_bin/"lspmux", "server"]
    keep_alive true
    error_log_path var/"log/lspmux.log"
    log_path var/"log/lspmux.log"

    # Need cargo and rust-analyzer in PATH
    environment_variables PATH: std_service_path_env
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
          "rootUri": null,
          "initializationOptions": {},
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
        "id": 2,
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

    begin
      pid = spawn bin/"lspmux", "server"
      sleep 5
      assert_match output, pipe_output(bin/"lspmux", input, 0)
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
