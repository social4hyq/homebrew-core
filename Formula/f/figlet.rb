class Figlet < Formula
  desc "Banner-like program prints strings as ASCII art"
  homepage "https://www.figlet.org/"
  url "ftp://ftp.figlet.org/pub/figlet/program/unix/figlet-2.2.5.tar.gz"
  mirror "https://fossies.org/linux/misc/figlet-2.2.5.tar.gz"
  sha256 "bf88c40fd0f077dab2712f54f8d39ac952e4e9f2e1882f1195be9e5e4257417d"
  license "BSD-3-Clause"

  livecheck do
    url "ftp://ftp.figlet.org/pub/figlet/program/unix/"
    regex(/figlet[._-]v?(\d+(?:\.\d+)+)\.t/i)
    strategy :page_match
  end

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "705ce68445d6632f8b7eaeb10f28773a306df9ab6ba83724a7f97d76840f72f3"
  end

  resource "contrib" do
    url "ftp://ftp.figlet.org/pub/figlet/fonts/contributed.tar.gz"
    mirror "https://www.minix3.org/distfiles-backup/figlet-fonts-20021023/contributed.tar.gz"
    mirror "https://downloads.sourceforge.net/project/fullauto/FIGlet%20Fonts/contributed.tar.gz"
    sha256 "2c569e052e638b28e4205023ae717f7b07e05695b728e4c80f4ce700354b18c8"
  end

  resource "intl" do
    url "ftp://ftp.figlet.org/pub/figlet/fonts/international.tar.gz"
    mirror "https://www.minix3.org/distfiles-backup/figlet-fonts-20021023/international.tar.gz"
    mirror "https://downloads.sourceforge.net/project/fullauto/FIGlet%20Fonts/international.tar.gz"
    sha256 "e6493f51c96f8671c29ab879a533c50b31ade681acfb59e50bae6b765e70c65a"
  end

  def install
    (pkgshare/"fonts").install resource("contrib"), resource("intl")

    chmod 0666, %w[Makefile showfigfonts]
    man6.mkpath
    bin.mkpath

    # OpenHarmony uses musl libc which lacks the glibc-specific macros
    # __BEGIN_DECLS / __END_DECLS. Provide fallback definitions.
    system "make", "prefix=#{prefix}",
                   "CFLAGS=-Wno-implicit-function-declaration -D__BEGIN_DECLS= -D__END_DECLS=",
                   "DEFAULTFONTDIR=#{pkgshare}/fonts",
                   "MANDIR=#{man}",
                   "install"
  end

  test do
    system bin/"figlet", "-f", "larry3d", "hello, figlet"
  end
end
