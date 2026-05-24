class Speedbump < Formula
  desc "TCP proxy for simulating variable, yet predictable network latency"
  homepage "https://github.com/kffl/speedbump"
  url "https://github.com/kffl/speedbump/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "ab685094e2e78818921adc8705ab01c8d26719d11313e99b9638b84ebae38194"
  license "Apache-2.0"
  head "https://github.com/kffl/speedbump.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3ea6641828ac76507fa54264aff292e3bd3c8bd06bd8740fc181c9b14dfe18c3"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    require "pty"
    port = free_port

    r, _, pid = PTY.spawn("#{bin}/speedbump --latency=100ms --port=#{port} localhost:80")
    assert_match "[INFO]  Started speedbump: port=#{port} dest=127.0.0.1:80", r.readline

    assert_match version.to_s, shell_output("#{bin}/speedbump --version 2>&1")
  ensure
    Process.kill("TERM", pid)
  end
end
