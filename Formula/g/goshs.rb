class Goshs < Formula
  desc "Simple, yet feature-rich web server written in Go"
  homepage "https://goshs.de"
  url "https://github.com/goshs-labs/goshs/archive/refs/tags/v2.1.4.tar.gz"
  sha256 "57645c607200cd762e018c27e091ea7a845a479bd356a602bad90498ebf0fe2a"
  license "MIT"
  head "https://github.com/goshs-labs/goshs.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "54efe78aff5670f868d8c5974f6c7103c8387903948fe114686d39f9bc21877f"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/goshs -v")

    (testpath/"test.txt").write "Hello, Goshs!"

    port = free_port
    pid = spawn bin/"goshs", "-p", port.to_s, "-d", testpath, "-si"
    output = shell_output("curl --retry 5 --retry-connrefused -s http://localhost:#{port}/test.txt")
    assert_match "Hello, Goshs!", output
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
