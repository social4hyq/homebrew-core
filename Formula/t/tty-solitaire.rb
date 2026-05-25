class TtySolitaire < Formula
  desc "Ncurses-based klondike solitaire game"
  homepage "https://github.com/mpereira/tty-solitaire"
  url "https://github.com/mpereira/tty-solitaire/archive/refs/tags/v1.4.1.tar.gz"
  sha256 "8eb536a87f0586e1f057a3aa05256df34cbd92a3e22545d1df2f945e27d89db2"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e0c856b77f94ae09d43b6ccc6b083261a19ce626457605bef2345867255717b2"
  end

  uses_from_macos "ncurses"

  def install
    system "make"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    system bin/"ttysolitaire", "-h"
  end
end
