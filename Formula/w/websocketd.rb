class Websocketd < Formula
  desc "WebSockets the Unix way"
  homepage "http://websocketd.com"
  url "https://github.com/joewalnes/websocketd/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "6b8fe0fad586d794e002340ee597059b2cfc734ba7579933263aef4743138fe5"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6cb38313af6c5c381b848ea770109c0d3e922851965065b0760c4d53dc29e7ef"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags:)
    man1.install "release/websocketd.man" => "websocketd.1"
  end

  test do
    port = free_port
    pid = spawn bin/"websocketd", "--port=#{port}", "echo", "ok"
    begin
      sleep 2
      assert_equal("404 page not found\n", shell_output("curl -s http://localhost:#{port}"))
    ensure
      Process.kill "TERM", pid
      Process.wait pid
    end
  end
end
