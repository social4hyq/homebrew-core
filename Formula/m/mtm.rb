class Mtm < Formula
  desc "Micro terminal multiplexer"
  homepage "https://github.com/deadpixi/mtm"
  url "https://github.com/deadpixi/mtm/archive/refs/tags/1.2.1/1.2.1.tar.gz"
  sha256 "2ae05466ef44efa7ddb4bce58efc425617583d9196b72e80ec1090bd77df598c"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4134d4d21e6efa4a092f8c5f686e7f57f0d910fbbc1797bac92e59a635659a56"
  end

  head do
    url "https://github.com/deadpixi/mtm.git", branch: "master"

    uses_from_macos "ncurses" # 1.2.2+ can use macOS' ncurses 5.7
  end

  depends_on "ncurses" # 1.2.1 requires newer than ncurses 6.1

  def install
    bin.mkpath
    man1.mkpath

    makefile = build.head? ? "Makefile.darwin" : "Makefile"

    system "make", "-f", makefile, "install", "DESTDIR=#{prefix}", "MANDIR=#{man1}"
    system "make", "-f", makefile, "install-terminfo"
  end

  test do
    require "open3"

    env = { "SHELL" => "/bin/sh", "TERM" => "xterm" }
    Open3.popen2(env, bin/"mtm") do |input, output, wait_thr|
      input.puts "printf 'TERM=%s PID=%s\n' $TERM $MTM"
      input.putc "\cG"
      sleep 1
      input.putc "w"

      assert_match "TERM=screen-bce PID=#{wait_thr.pid}", output.read
    end
  end
end
