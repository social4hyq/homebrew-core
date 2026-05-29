class Dvdbackup < Formula
  desc "Rip DVD's from the command-line"
  homepage "https://dvdbackup.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/dvdbackup/dvdbackup/dvdbackup-0.4.2/dvdbackup-0.4.2.tar.gz"
  sha256 "0a37c31cc6f2d3c146ec57064bda8a06cf5f2ec90455366cb250506bab964550"
  license "GPL-3.0-or-later"
  revision 3

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0dc14d22ef29fb2ab56d83fa0c625fe89178bbd906bd9d3a9bd50c20aef3d112"
  end

  depends_on "libdvdread"

  # Fix compatibility with libdvdread 6.1.0. See:
  # https://bugs.launchpad.net/dvdbackup/+bug/1869226
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/dvdbackup/compat.patch"
    sha256 "12d54bc08b0eb2acf6429c256373d1d98ba3f6f14821c2bebbbb571eb7b9d82b"
  end

  def install
    system "./configure", "--mandir=#{man}",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"dvdbackup", "--version"
  end
end
