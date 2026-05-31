class Libnghttp3 < Formula
  desc "HTTP/3 library written in C"
  homepage "https://nghttp2.org/nghttp3/"
  url "https://github.com/ngtcp2/nghttp3/releases/download/v1.16.0/nghttp3-1.16.0.tar.xz"
  mirror "http://fresh-center.net/linux/www/nghttp3-1.16.0.tar.xz"
  sha256 "776f59a99905c9a348846807b2e5ac9bb3485fc0f8c0250ba803018d5238a16e"
  license "MIT"
  compatibility_version 1
  head "https://github.com/ngtcp2/nghttp3.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bc1a30f5c2a02ea0d43b7d5864b7b07f6743383d9fcfa807f22ed85a6f5b2d75"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-DENABLE_LIB_ONLY=1", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <nghttp3/nghttp3.h>

      int main(void) {
        nghttp3_qpack_decoder *decoder;
        if (nghttp3_qpack_decoder_new(&decoder, 4096, 0, nghttp3_mem_default()) != 0) {
          return 1;
        }
        nghttp3_qpack_decoder_del(decoder);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-o", "test", "-I#{include}", "-L#{lib}", "-lnghttp3"
    system "./test"
  end
end
