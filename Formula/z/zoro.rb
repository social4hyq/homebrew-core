class Zoro < Formula
  desc "Expose local server to external network"
  homepage "https://github.com/txthinking/zoro"
  url "https://github.com/txthinking/zoro/archive/refs/tags/v20240828.tar.gz"
  sha256 "8b41550a1d42fa2c0a67d7115978efff126ab6fff30d774ce902febd0b682c5c"
  license "GPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ab89614eda6095d0362abd4f15044575a9c01a10de5a4410b49b3823a94da9ce"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cli/zoro"
  end

  test do
    (testpath/"index.html").write <<~HTML
      <!DOCTYPE HTML>
      <html>
      <body>
        <p>passed</p>
      </body>
      </html>
    HTML
    zoro_server_port = free_port
    server_port = free_port
    client_port = free_port
    server_pid = spawn bin/"zoro", "server", "-l", ":#{zoro_server_port}", "-p", "password"
    sleep 5
    client_pid = spawn bin/"zoro", "client", "-s", "127.0.0.1:#{zoro_server_port}",
                                             "-p", "password",
                                             "--serverport", server_port.to_s,
                                             "--dir", testpath,
                                             "--dirport", client_port.to_s
    sleep 3
    output = shell_output "curl 127.0.0.1:#{server_port}"
    assert_match "passed", output
  ensure
    Process.kill "SIGTERM", server_pid, client_pid
  end
end
