class Xa < Formula
  desc "6502 cross assembler"
  homepage "https://www.floodgap.com/retrotech/xa/"
  url "http://ftp.debian.org/debian/pool/main/x/xa/xa_2.4.1.orig.tar.gz"
  sha256 "63c12a6a32a8e364f34f049d8b2477f4656021418f08b8d6b462be0ed3be3ac3"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href\s*?=.*?xa[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c3b786d89ab1ed2d98b90553b8faa3a0750fd33e3c49321f412dbbaac742cad6"
  end

  def install
    system "make", "CC=#{ENV.cc}",
                   "CFLAGS=#{ENV.cflags}",
                   "DESTDIR=#{prefix}",
                   "install"
  end

  test do
    (testpath/"foo.a").write "jsr $ffd2\n"

    system bin/"xa", "foo.a"
    code = File.open("a.o65", "rb") { |f| f.read.unpack("C*") }
    assert_equal [0x20, 0xd2, 0xff], code
  end
end
