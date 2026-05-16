class Moe < Formula
  desc "Console text editor for ISO-8859 and ASCII"
  homepage "https://www.gnu.org/software/moe/moe.html"
  url "https://ftpmirror.gnu.org/gnu/moe/moe-1.16.tar.lz"
  mirror "https://ftp.gnu.org/gnu/moe/moe-1.16.tar.lz"
  sha256 "4c25cd78919272aebec0a7f8c126011bb5a4b5d87422807a3423216f0a17a868"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bb27057a53a515e78670a0531dc1272ec8390f6a30c81967faa62e12afdbe5f8"
  end

  uses_from_macos "ncurses"

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"moe", "--version"
  end
end
