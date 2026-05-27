class TsnetServe < Formula
  desc "Expose HTTP applications to a Tailscale Tailnet network"
  homepage "https://github.com/shayne/tsnet-serve"
  url "https://github.com/shayne/tsnet-serve/archive/refs/tags/v1.3.2.tar.gz"
  sha256 "05d11ec7ac4e1bdb2ce6a8db3999e314ceab51ee7b462df3ec75895704438cc7"
  license "MIT"
  head "https://github.com/shayne/tsnet-serve.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8929b4d99eb2b16c957a454e9a03f4bb1ae653aa000438dd8232de3c024730f3"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tsnet-serve -version")

    hostname = "test"
    backend = "http://localhost:8080"

    logfile = testpath/"tsnet-serve.log"
    pid = spawn bin/"tsnet-serve", "-hostname", hostname, "-backend", backend,
                out: logfile.to_s, err: logfile.to_s

    sleep 1

    output = logfile.read
    assert_match "tsnet starting with hostname \"#{hostname}\"", output
    assert_match "LocalBackend state is NeedsLogin", output
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
