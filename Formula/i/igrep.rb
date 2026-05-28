class Igrep < Formula
  desc "Interactive grep"
  homepage "https://github.com/konradsz/igrep"
  url "https://github.com/konradsz/igrep/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "c4ccd55082f2957dab3766b4c7229c3f804d578a8214ef2ce23f13029bdd2296"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "315b1934b9b4d560c66d0d22aa6e5fa815c0b2969efd18003b7c4d9f509685d4"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    require "pty"
    require "io/console"
    require "expect"

    (testpath/"test.txt").write <<~EOS
      This is a test of the Homebrew formula 'igrep'.
    EOS
    PTY.spawn(bin/"ig", "a test", ".") do |r, w, pid|
      r.winsize = [80, 130]
      refute_nil r.expect("test.txt", 3), "Expected test.txt"
      w.write "q"
      r.read
    rescue Errno::EIO
      # GNU/Linux raises EIO when read is done on closed pty
    ensure
      r.close
      w.close
      Process.wait(pid)
    end
  end
end
