class Charls < Formula
  desc "C++ JPEG-LS library implementation"
  homepage "https://github.com/team-charls/charls"
  url "https://github.com/team-charls/charls/archive/refs/tags/2.4.4.tar.gz"
  sha256 "fbd712903d61306ad00d5fa5029a9882630c7311ca487f48d2d76000956e8ff9"
  license "BSD-3-Clause"
  revision 1
  head "https://github.com/team-charls/charls.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "93d3e60b8ae52a4fc58349783a509c1dfd7121f5c5315c21d9614d0404f599b1"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DCHARLS_BUILD_TESTS=OFF
      -DCHARLS_BUILD_FUZZ_TEST=OFF
      -DCHARLS_BUILD_SAMPLES=OFF
      -DBUILD_SHARED_LIBS=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <charls/charls.h>
      #include <iostream>

      int main() {
        charls::jpegls_encoder encoder;
        std::cout << "ok" << std::endl;
        return 0;
      }
    CPP

    system ENV.cxx, "test.cpp", "-std=c++14", "-I#{include}", "-L#{lib}", "-lcharls", "-o", "test"
    assert_equal "ok", shell_output(testpath/"test").chomp
  end
end
