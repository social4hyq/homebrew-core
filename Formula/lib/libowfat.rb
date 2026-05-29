class Libowfat < Formula
  desc "Reimplements libdjb"
  homepage "http://www.fefe.de/libowfat/"
  url "https://deb.debian.org/debian/pool/main/libo/libowfat/libowfat_0.34.orig.tar.xz"
  mirror "http://www.fefe.de/libowfat/libowfat-0.34.tar.xz"
  sha256 "d4330d373ac9581b397bc24a22ad1f7f5d58a7fe36d9d239fe352ceffc5d304b"
  license "GPL-2.0-only"
  head ":pserver:cvs:@cvs.fefe.de:/cvs", using: :cvs

  livecheck do
    url :homepage
    regex(/href=.*?libowfat[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "df9c834bde0a0cf804e998a0d77b6ecbf90b30c8e2d47e0eccc533e61425a9cf"
  end

  def install
    system "make", "libowfat.a"
    system "make", "install", "prefix=#{prefix}", "MAN3DIR=#{man3}"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <libowfat/str.h>
      int main()
      {
        return str_diff("a", "a");
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lowfat", "-o", "test"
    system "./test"
  end
end
