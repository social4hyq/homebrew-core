class TofuLs < Formula
  desc "OpenTofu Language Server"
  homepage "https://github.com/opentofu/tofu-ls"
  url "https://github.com/opentofu/tofu-ls/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "6e6ba0f69a85cd9cc59a545c8fe6fa85ffd1ae0fe1989422cc24b1c05f08a5f4"
  license "MPL-2.0"
  head "https://github.com/opentofu/tofu-ls.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1f4643f44ffe37d9821fb625522ade113c0c8c8a9136bc4b42af075aa11fb6df"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.rawVersion=#{version}+#{tap.user}
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    port = free_port

    pid = spawn bin/"tofu-ls", "serve", "-port", port.to_s, File::NULL
    begin
      sleep 2
      tcp_socket = TCPSocket.new("localhost", port)
      tcp_socket.puts <<~EOF
        Content-Length: 59

        {"jsonrpc":"2.0","method":"initialize","params":{},"id":1}
      EOF
      assert_match "Content-Type", tcp_socket.gets("\n")
    ensure
      Process.kill("SIGINT", pid)
      Process.wait(pid)
    end
  end
end
