class Miniaudio < Formula
  desc "Audio playback and capture library"
  homepage "https://miniaud.io"
  url "https://github.com/mackron/miniaudio/archive/refs/tags/0.11.25.tar.gz"
  sha256 "b900edcffe979816e2560a0580b9b1216d674b4f17fbadeca8f777a7f8ab0274"
  license any_of: [:public_domain, "MIT-0"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b93f7dbd70ca79ec93e3e4faaacb84928531f868d3d53e86cd8bf91bf5f79304"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DMINIAUDIO_BUILD_EXAMPLES=OFF
      -DMINIAUDIO_BUILD_TESTS=OFF
      -DMINIAUDIO_INSTALL=ON
      -DBUILD_SHARED_LIBS=ON
      -DMINIAUDIO_NO_EXTRA_NODES=ON
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <miniaudio/miniaudio.h>
      int main(void) {
        ma_context context;
        if (ma_context_init(NULL, 0, NULL, &context) != MA_SUCCESS) return 1;
        ma_context_uninit(&context);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-o", "test", "-I#{include}", "-L#{lib}", "-lminiaudio", "-lm"
    system "./test"
  end
end
