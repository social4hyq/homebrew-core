class Dialog < Formula
  desc "Display user-friendly message boxes from shell scripts"
  homepage "https://invisible-island.net/dialog/"
  url "https://invisible-mirror.net/archives/dialog/dialog-1.3-20260721.tgz"
  sha256 "62bdf59057d4f760a1cc2217827f07887b4a3eebf694c25eacd4803d2171cdc6"
  license "LGPL-2.1-or-later"
  compatibility_version 1

  livecheck do
    url "https://invisible-mirror.net/archives/dialog/"
    regex(/href=.*?dialog[._-]v?(\d+(?:\.\d+)+-\d{6,8})\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d5094c5a0bbcd2ecdac9fe63f26c1d81cb614411508b16f13607d0946e0829ea"
  end

  uses_from_macos "ncurses"

  def install
    system "./configure", "--prefix=#{prefix}", "--with-ncurses"
    system "make", "install-full"
  end

  test do
    system bin/"dialog", "--version"
  end
end
