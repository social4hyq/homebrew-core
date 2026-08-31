class Serve < Formula
  desc "Static http server anywhere you need one"
  homepage "https://github.com/syntaqx/serve"
  url "https://github.com/syntaqx/serve/archive/refs/tags/v0.8.0.tar.gz"
  sha256 "636223c5b9d9af83601ad82be5dd8788bd35b58160f4420a899e00fc82e7618d"
  license "MIT"
  head "https://github.com/syntaqx/serve.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "33b5f920795afe100105a935b81f457dc1df00bb0e4c011264907ee30c7460f9"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-X main.version=#{version}"), "./cmd/serve"
  end

  test do
    (testpath/"index.html").write("<h1>serve</h1>")
    port = free_port
    pid = spawn bin/"serve", "-port", port.to_s
    sleep 1
    output = shell_output("curl -sI http://localhost:#{port}")
    assert_match(/200 OK/m, output)
  ensure
    Process.kill("HUP", pid)
  end
end
