class Libxdiff < Formula
  desc "Implements diff functions for binary and text files"
  homepage "http://www.xmailserver.org/xdiff-lib.html"
  url "http://www.xmailserver.org/libxdiff-0.23.tar.gz"
  sha256 "e9af96174e83c02b13d452a4827bdf47cb579eafd580953a8cd2c98900309124"
  license "LGPL-2.1-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4cf7895f933f02bba9572877a474bc40db166848b7ec1b95fc521559d684b7a5"
  end

  deprecate! date: "2026-01-05", because: "is not available via HTTPS"
  disable! date: "2027-01-05", because: "is not available via HTTPS"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  def install
    system "autoreconf", "--force", "--verbose", "--install"
    system "./configure", "--mandir=#{man}", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <xdiff.h>
      int main(void) {
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lxdiff", "-o", "test"
    system "./test"
  end
end
