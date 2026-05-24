class Pcal < Formula
  desc "Generate Postscript calendars without X"
  homepage "https://pcal.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/pcal/pcal/pcal-4.11.0/pcal-4.11.0.tgz"
  sha256 "8406190e7912082719262b71b63ee31a98face49aa52297db96cc0c970f8d207"
  license :cannot_represent

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "122ceacdf65890d850c25e66b772f30e32ce82edf11a4dbbc1381cce268047ca"
  end

  uses_from_macos "mandoc" => :build
  uses_from_macos "ncompress" => :build

  def install
    # mandoc is only available since Ventura, but groff is available for older macOS
    inreplace "Makefile", /[gn]roff /, "mandoc " if !OS.mac? || MacOS.version >= :ventura

    ENV.deparallelize
    system "make", "CC=#{ENV.cc}", "CFLAGS=#{ENV.cflags}"
    system "make", "install", "BINDIR=#{bin}", "MANDIR=#{man1}",
                              "CATDIR=#{man}/cat1"
  end

  test do
    system bin/"pcal"
  end
end
