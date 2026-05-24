class ApacheBrooklynCli < Formula
  desc "Apache Brooklyn command-line interface"
  homepage "https://brooklyn.apache.org"
  url "https://github.com/apache/brooklyn-client/archive/refs/tags/rel/apache-brooklyn-1.1.0.tar.gz"
  sha256 "0c9ec77413e88d4ca23d0821c4d053b7cc69818962d4ccb9e7082c9d1dea7146"
  license "Apache-2.0"
  head "https://github.com/apache/brooklyn-client.git", branch: "master"

  livecheck do
    url :stable
    regex(%r{^(?:rel/)?apache-brooklyn[._-]v?(\d+(?:\.\d+)+)$}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7b9db296d30f3adf534f4797100b087b7fac0a07da0c49144d9d19cdf6a9ccde"
  end

  depends_on "go" => :build

  def install
    cd "cli" do
      system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"br"), "./br"
    end
  end

  test do
    port = free_port
    server = TCPServer.new("localhost", port)
    pid_mock_brooklyn = fork do
      loop do
        socket = server.accept
        response = '{"version":"1.2.3","buildSha1":"dummysha","buildBranch":"1.2.3"}'
        socket.print "HTTP/1.1 200 OK\r\n" \
                     "Content-Type: application/json\r\n" \
                     "Content-Length: #{response.bytesize}\r\n" \
                     "Connection: close\r\n"
        socket.print "\r\n"
        socket.print response
        socket.close
      end
    end

    begin
      mock_brooklyn_url = "http://localhost:#{port}"
      assert_equal "Connected to Brooklyn version 1.2.3 at #{mock_brooklyn_url}\n",
        shell_output("#{bin}/br login #{mock_brooklyn_url} username password")
    ensure
      Process.kill("KILL", pid_mock_brooklyn)
    end
  end
end
