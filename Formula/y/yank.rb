class Yank < Formula
  desc "Copy terminal output to clipboard"
  homepage "https://github.com/mptre/yank"
  url "https://github.com/mptre/yank/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "40f5472df5f6356a4d6f48862a19091bd4de3f802b3444891b3bc4b710fb35ca"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f1f4b04026c14f5d8c8508fc64c8c30fc7577d5f5f32debce668fed381e59a20"
  end

  on_linux do
    depends_on "xsel"
  end

  def install
    yankcmd = OS.mac? ? "pbcopy" : "xsel"
    system "make", "install", "PREFIX=#{prefix}", "YANKCMD=#{yankcmd}"
  end

  test do
    require "pty"
    PTY.spawn("echo key=value | #{bin}/yank -d = >#{testpath}/result") do |r, w, _pid|
      r.winsize = [80, 43]
      w.write "\016"
      sleep 1
      w.write "\r"
      sleep 1
    end
    assert_equal "value", (testpath/"result").read
  end
end
