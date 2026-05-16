class Shell2http < Formula
  desc "Executing shell commands via HTTP server"
  homepage "https://github.com/msoap/shell2http"
  url "https://github.com/msoap/shell2http/archive/refs/tags/v1.17.0.tar.gz"
  sha256 "17fab67e34e767accfbc59ab504971c704f54d79b57a023e6b5efa5556994624"
  license "MIT"
  head "https://github.com/msoap/shell2http.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fff12dfd68e30e0482244e71f11d02812f75680c6cecb707f815a54afffae2ba"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags:)

    man1.install "shell2http.1"
  end

  test do
    port = free_port
    pid = spawn bin/"shell2http", "-port", port.to_s, "/echo", "echo brewtest"
    sleep 1
    output = shell_output("curl -s http://localhost:#{port}")
    assert_match "Served by shell2http/#{version}", output

    output = shell_output("curl -s http://localhost:#{port}/echo")
    assert_match "brewtest", output
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
