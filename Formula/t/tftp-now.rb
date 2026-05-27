class TftpNow < Formula
  desc "Single-binary TFTP server and client that you can use right now"
  homepage "https://github.com/puhitaku/tftp-now"
  url "https://github.com/puhitaku/tftp-now/archive/refs/tags/1.2.0.tar.gz"
  sha256 "428c9ef7336644e748c280277495e3ec724f0c0c38f3724de5f1e4c42d8431c6"
  license "MIT"
  head "https://github.com/puhitaku/tftp-now.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "48dde91325c3ef96e7295d1245d53edad03b2aed83c69066819feece37d46938"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", tags: "netgo")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tftp-now help", 1)

    port = free_port
    pid = fork { exec bin/"tftp-now", "serve", "-port", port.to_s, "-root", testpath }
    sleep 1
    (testpath/"testfile").write "Hello, world!"

    output = pipe_output("#{bin}/tftp-now read -host 127.0.0.1 " \
                         "-port #{port} -local - -remote testfile", (testpath/"testfile").read)
    output = output.gsub(/\e\[\d+(;\d+)?m/, "")
    assert_match "start reading blocksize=512 host=127.0.0.1:#{port} local=- remote=testfile", output
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
