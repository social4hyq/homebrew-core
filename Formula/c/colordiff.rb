class Colordiff < Formula
  desc "Color-highlighted diff(1) output"
  homepage "https://www.colordiff.org/"
  url "https://www.colordiff.org/colordiff-1.0.22.tar.gz"
  sha256 "f96f73c54521c53f14dc164d5a3920c9ca21a0e5f8e9613f43812a98af3e22af"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?colordiff[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  depends_on "coreutils" => :build # GNU install
  depends_on "perl"

  def install
    man1.mkpath
    system "make", "INSTALL=install",
                   "INSTALL_DIR=#{bin}",
                   "ETC_DIR=#{etc}",
                   "MAN_DIR=#{man1}",
                   "install"

    inreplace bin/"colordiff", "/usr/local", HOMEBREW_PREFIX if OS.mac? && Hardware::CPU.intel?

    # OpenHarmony has no /usr/bin/perl; rewrite shebang to the brewed perl.
    perl_bin = Formula["perl"].opt_bin/"perl"
    inreplace bin/"colordiff", /^#!\/usr\/bin\/perl/, "#!#{perl_bin}"
  end

  test do
    cp HOMEBREW_PREFIX/"bin/brew", "brew1"
    cp HOMEBREW_PREFIX/"bin/brew", "brew2"
    system bin/"colordiff", "brew1", "brew2"
  end
end
