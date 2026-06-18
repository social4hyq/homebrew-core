class Aribb24 < Formula
  desc "Library for ARIB STD-B24, decoding JIS 8 bit characters and parsing MPEG-TS"
  homepage "https://code.videolan.org/jeeb/aribb24"
  url "https://code.videolan.org/jeeb/aribb24/-/archive/v1.0.4/aribb24-v1.0.4.tar.bz2"
  sha256 "88b58dd760609372701087e25557ada9f7c6d973306c017067c5dcaf9e2c9710"
  license "LGPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e2083c50a3cf77a9f3c3d0d5739e55bf7bd7ef18cc800cdd8c74a60b8a5f6fab"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "libpng"

  def install
    system "./bootstrap"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <aribb24/aribb24.h>
      #include <stdlib.h>
      int main() {
        arib_instance_t *ptr = arib_instance_new(NULL);
        if (!ptr)
          return 1;
        arib_instance_destroy(ptr);
        return 0;
      }
    C
    system ENV.cc, "-o", "test", "test.c", "-I#{include}",
                   "-L#{lib}", "-laribb24"
    system "./test"
  end
end
