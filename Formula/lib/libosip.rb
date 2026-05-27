class Libosip < Formula
  desc "Implementation of the eXosip2 stack"
  homepage "https://www.gnu.org/software/osip/"
  url "https://ftpmirror.gnu.org/gnu/osip/libosip2-5.3.1.tar.gz"
  mirror "https://ftp.gnu.org/gnu/osip/libosip2-5.3.1.tar.gz"
  sha256 "fe82fe841608266ac15a5c1118216da00c554d5006e2875a8ac3752b1e6adc79"
  license "LGPL-2.1-or-later"

  livecheck do
    url :stable
    regex(/href=.*?libosip2[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2a671c6204131c80ac44c398ff3afe6094af8c2741722d77c43fac77860f5c4b"
  end

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <sys/time.h>
      #include <osip2/osip.h>

      int main() {
          osip_t *osip;
          int i = osip_init(&osip);
          if (i != 0)
            return -1;
          return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-losip2", "-o", "test"
    system "./test"
  end
end
