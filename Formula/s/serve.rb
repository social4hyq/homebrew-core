class Serve < Formula
  desc "Static http server anywhere you need one"
  homepage "https://github.com/syntaqx/serve"
  url "https://github.com/syntaqx/serve/archive/refs/tags/v0.7.1.tar.gz"
  sha256 "a557da378ecf66d34585542b365daf6e35e1e926452f4bb96f6ab1b151c66e0b"
  license "MIT"
  head "https://github.com/syntaqx/serve.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3d2992f3b9231d42bfb60fda46c998aa8b8932a18a6becb16db730bf09c0a680"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/serve"
  end

  test do
    port = free_port
    pid = spawn bin/"serve", "-port", port.to_s
    sleep 1
    output = shell_output("curl -sI http://localhost:#{port}")
    assert_match(/200 OK/m, output)
  ensure
    Process.kill("HUP", pid)
  end
end
