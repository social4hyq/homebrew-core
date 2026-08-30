class ChiselTunnel < Formula
  desc "Fast TCP/UDP tunnel over HTTP"
  homepage "https://github.com/jpillora/chisel"
  url "https://github.com/jpillora/chisel/archive/refs/tags/v1.12.0.tar.gz"
  sha256 "5c25f054b64814f770725593db525faa1999960aecf4eb15c86529dea573c431"
  license "MIT"
  head "https://github.com/jpillora/chisel.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ec7de414e4e66cfb8bdf4848ba76ccfe702e0d8a4407846c9ff5efc8ea0ab72a"
  end

  depends_on "go" => :build

  conflicts_with "chisel", because: "both install `chisel` binaries"
  conflicts_with "foundry", because: "both install `chisel` binaries"

  def install
    ldflags = "-s -w -X github.com/jpillora/chisel/share.BuildVersion=v#{version}"
    system "go", "build", *std_go_args(ldflags:, output: bin/"chisel")
  end

  test do
    server_port = free_port
    server_pid = spawn bin/"chisel", "server", "-p", server_port.to_s, [:out, :err] => File::NULL

    begin
      sleep 2
      assert_match "Connected", shell_output("curl -v 127.0.0.1:#{server_port} 2>&1")
    ensure
      Process.kill("TERM", server_pid)
      Process.wait(server_pid)
    end
  end
end
