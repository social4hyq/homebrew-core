class Gaze < Formula
  desc "Execute commands for you"
  homepage "https://github.com/wtetsu/gaze"
  url "https://github.com/wtetsu/gaze/archive/refs/tags/v1.2.1.tar.gz"
  sha256 "ba2878f5b0ddd385afbe6c8b3fcf92acdcd722113b97e52d2fafc53ee3cef918"
  license "MIT"
  head "https://github.com/wtetsu/gaze.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0a65222c2e8468d5d5cd54d53b9793ef1da67ae1996cfe91d2bcf9e238b238e8"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "cmd/gaze/main.go"
  end

  test do
    pid = spawn bin/"gaze", "-c", "cp test.txt out.txt", "test.txt"
    sleep 5
    File.write("test.txt", "hello, world!")
    sleep 2
    Process.kill("TERM", pid)
    assert_match("hello, world!", File.read("out.txt"))
  end
end
