class SatelliteTracker < Formula
  desc "Terminal-based real-time satellite tracking and orbit prediction application"
  homepage "https://github.com/ShenMian/tracker"
  url "https://github.com/ShenMian/tracker/archive/refs/tags/v0.1.20.tar.gz"
  sha256 "9a5ff9f12230b6821805a07a76e61420d52f0ed60ee4a5da2cc37917abdebebf"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "67fb91c371ccbe24cbc7ab40fc28e84e670021a13dc38116985bfeed99ca3189"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@4"
  end

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tracker --version")

    output_log = testpath/"output.log"
    if OS.mac?
      pid = spawn bin/"tracker", [:out, :err] => output_log.to_s
    else
      require "pty"
      r, _w, pid = PTY.spawn(bin/"tracker", [:out, :err] => output_log.to_s)
      r.winsize = [80, 43]
    end
    sleep 2
    assert_match "World map", output_log.read
  ensure
    Process.kill("KILL", pid)
    Process.wait(pid)
  end
end
