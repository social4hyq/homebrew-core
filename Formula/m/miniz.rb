class Miniz < Formula
  desc "Lossless, high-performance data compression library (zlib/Deflate)"
  homepage "https://github.com/richgel999/miniz"
  url "https://github.com/richgel999/miniz/archive/refs/tags/3.1.1.tar.gz"
  sha256 "8bb29c7bd6f22356e5583e794bed4a0b3e6dfcbcadb49974fc9270ccca1e5557"
  license "MIT"
  head "https://github.com/richgel999/miniz.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c7120e7041b2cb06754b6c6067286cc7bd35addb73e990fd06c6482daba3308a"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DBUILD_SHARED_LIBS=ON
      -DBUILD_EXAMPLES=OFF
      -DBUILD_TESTS=OFF
      -DBUILD_FUZZERS=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <miniz/miniz.h>
      #include <string.h>
      #include <stdio.h>

      int main(void) {
        const char *src = "The quick brown fox jumps over the lazy dog. "
                          "The quick brown fox jumps over the lazy dog.";
        mz_ulong src_len = (mz_ulong)strlen(src);
        unsigned char compressed[256];
        unsigned char roundtrip[256];
        mz_ulong compressed_len = sizeof(compressed);
        mz_ulong roundtrip_len  = sizeof(roundtrip);

        if (mz_compress(compressed, &compressed_len,
                        (const unsigned char *)src, src_len) != MZ_OK) return 1;
        if (mz_uncompress(roundtrip, &roundtrip_len,
                          compressed, compressed_len) != MZ_OK) return 2;
        if (roundtrip_len != src_len) return 3;
        if (memcmp(roundtrip, src, src_len) != 0) return 4;

        printf("%s\\n", mz_version());
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lminiz", "-o", "test"
    assert_match(/^\d+\.\d+\.\d+/, shell_output("./test"))
  end
end
