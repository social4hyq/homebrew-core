class LsHpack < Formula
  desc "HTTP/2 HPACK header compression library"
  homepage "https://github.com/litespeedtech/ls-hpack"
  url "https://github.com/litespeedtech/ls-hpack/archive/refs/tags/v2.3.5.tar.gz"
  sha256 "430a1a36029e0ae1c81eaa0b2356920f1e65fde1cdd722351c671ebe513b7a96"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8b8379fd3cf9c8d57ae5b592d779638f8a297a5e9ae0e0ed4385e73d14d6f596"
  end

  depends_on "cmake" => :build

  def install
    # Upstream has no install() rules in CMakeLists, so install artifacts manually.
    # https://github.com/litespeedtech/ls-hpack/issues/21
    system "cmake", "-S", ".", "-B", "build",
                  "-DCMAKE_BUILD_TYPE=Release",
                  "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
                  "-DSHARED=1",
                  "-DLSHPACK_XXH=1",
                  *std_cmake_args
    system "cmake", "--build", "build"

    lib.install "build/#{shared_library("libls-hpack")}"
    include.install "lshpack.h", "lsxpack_header.h"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <assert.h>
      #include <lshpack.h>

      int main(void) {
        struct lshpack_dec dec;
        lshpack_dec_init(&dec);
        lshpack_dec_cleanup(&dec);
        assert(LSHPACK_MAJOR_VERSION >= 2);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lls-hpack", "-o", "test"
    system "./test"
  end
end
