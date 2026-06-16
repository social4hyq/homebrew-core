class Sendme < Formula
  desc "Tool to send files and directories, based on iroh"
  homepage "https://iroh.computer/sendme"
  url "https://github.com/n0-computer/sendme/archive/refs/tags/v0.36.0.tar.gz"
  sha256 "69897a9785c5b87c769417f77de8bff6e34e5391eed3d2df5d270599daf485ad"
  license "MIT"
  head "https://github.com/n0-computer/sendme.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "27774b29f3c5daef83aff952ad6f8c228c420ac26bbea61f2771e06affc6cebb"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sendme --version")

    begin
      output_log = testpath/"output.log"
      pid = spawn bin/"sendme", "send", bin/"sendme", [:out, :err] => output_log.to_s
      sleep 4
      assert_match "imported file #{bin}/sendme", output_log.read
      assert_match "to get this data, use\nsendme receive", output_log.read
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
