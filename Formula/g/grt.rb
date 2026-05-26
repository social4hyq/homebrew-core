class Grt < Formula
  desc "Gesture Recognition Toolkit for real-time machine learning"
  homepage "https://nickgillian.com/grt/"
  url "https://github.com/nickgillian/grt/archive/refs/tags/v0.2.4.tar.gz"
  sha256 "55bcabe7a58916461dc4341758eff2a45bd5b236c263dfe6e58c176c1a7e1ac4"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "77deec166c1e73fb13dafc26faeac58883ddda222fe6fa35d8d3792fe49a1cd4"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DBUILD_TESTS=OFF
      -DBUILD_EXAMPLES=OFF
    ]
    # Workaround to build with CMake 4
    args << "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    system "cmake", "-S", "build", "-B", "_build", *args, *std_cmake_args
    system "cmake", "--build", "_build"
    system "cmake", "--install", "_build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <GRT/GRT.h>
      int main() {
        GRT::GestureRecognitionPipeline pipeline;
        return 0;
      }
    CPP
    system ENV.cxx, "test.cpp", "-std=c++11", "-I#{include}", "-L#{lib}", "-lgrt", "-o", "test"
    system "./test"
  end
end
