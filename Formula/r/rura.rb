class Rura < Formula
  desc "Interactive TUI scratchpad for building shell pipelines"
  homepage "https://github.com/tlipinski/rura"
  url "https://github.com/tlipinski/rura/archive/refs/tags/v1.9.0.tar.gz"
  sha256 "53f7ee8e24cfce1bcf1c7c51239db7f493a696f7b94e6d2519016599c560b025"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8815d940d244d42b9a7b98caa4e06dd19de34fcf083b0b08f50cfc3a5a1dd767"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    require "expect"
    require "pty"

    (testpath/"test.txt").write <<~EOS
      Hello
      world
    EOS
    PTY.spawn(bin/"rura", "--file", "test.txt") do |r, w, pid|
      r.expect "1 Hello"
      w.write "tac\r"
      r.expect "1 world"
      w.write "|sha256sum\r"
      r.expect "1 bdaadfc45abaf"
    rescue Errno::EIO
      # GNU/Linux raises EIO when read is done on closed pty
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
