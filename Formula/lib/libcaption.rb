class Libcaption < Formula
  desc "Free open-source CEA608 / CEA708 closed-caption encoder/decoder"
  homepage "https://github.com/szatmary/libcaption"
  url "https://github.com/szatmary/libcaption/archive/refs/tags/v0.8.tar.gz"
  sha256 "8567765a457de43a6e834502cf42fd0622901428d9820c73495df275e01cb904"
  license "MIT"
  head "https://github.com/szatmary/libcaption.git", branch: "develop"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e06cb0fcc39462f6ddaa2838d55b8ad9be9fc348db8e8d45d87b7fb6e27a518c"
  end

  depends_on "cmake" => :build

  def install
    ENV["CMAKE_POLICY_VERSION_MINIMUM"] = "3.5"
    system "cmake", "-S", ".", "-B", "build",
                    "-DBUILD_EXAMPLES=OFF",
                    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON",
                    "-DBUILD_SHARED_LIBS=ON",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <caption/cea708.h>
      int main(void) {
        caption_frame_t ccframe;
        caption_frame_init(&ccframe);
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lcaption", "-o", "test"
    system "./test"
  end
end
