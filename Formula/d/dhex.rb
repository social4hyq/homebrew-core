class Dhex < Formula
  desc "Ncurses based advanced hex editor featuring diff mode and more"
  homepage "https://www.dettus.net/dhex/"
  url "https://www.dettus.net/dhex/dhex_0.69.tar.gz"
  sha256 "52730bcd1cf16bd4dae0de42531be9a4057535ec61ca38c0804eb8246ea6c41b"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?dhex[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "52723f737ef962f668d8e002dd773a66ced9039fe7593f0953b84b85fbc15c43"
  end

  uses_from_macos "ncurses"

  def install
    inreplace "Makefile", "$(DESTDIR)/man", "$(DESTDIR)/share/man"
    bin.mkpath
    man1.mkpath
    man5.mkpath
    system "make", "install", "DESTDIR=#{prefix}"
  end

  test do
    assert_match("GNU GENERAL PUBLIC LICENSE",
                 pipe_output("#{bin}/dhex -g 2>&1", "", 0))
  end
end
