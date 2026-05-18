class Libebur128 < Formula
  desc "Library implementing the EBU R128 loudness standard"
  homepage "https://github.com/jiixyj/libebur128"
  url "https://github.com/jiixyj/libebur128/archive/refs/tags/v1.2.6.tar.gz"
  sha256 "baa7fc293a3d4651e244d8022ad03ab797ca3c2ad8442c43199afe8059faa613"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "eedeb418399a9ab4da5bd2c01066ea3bea45362a5b9b721d03a7f97307de6a9f"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "speex"

  def install
    # Upstream issue for CMake 4 workaround: https://github.com/jiixyj/libebur128/issues/134
    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_POLICY_VERSION_MINIMUM=3.5", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <ebur128.h>
      int main() {
        ebur128_init(5, 44100, EBUR128_MODE_I);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-L#{lib}", "-lebur128", "-o", "test"
    system "./test"
  end
end
