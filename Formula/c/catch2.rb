class Catch2 < Formula
  desc "Modern, C++-native, test framework"
  homepage "https://github.com/catchorg/Catch2"
  url "https://github.com/catchorg/Catch2/archive/refs/tags/v3.16.0.tar.gz"
  sha256 "0957cae5821b17ce07f0833aaa52b5137643a8382203221f363a8303c109af34"
  license "BSL-1.0"
  revision 1
  head "https://github.com/catchorg/Catch2.git", branch: "devel"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e6fcd0e4959739c9c3ab3d257bd666c3078d81162eba697cabc7abf92bf832ca"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_CXX_STANDARD=17", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <catch2/catch_all.hpp>
      TEST_CASE("Basic", "[catch2]") {
        int x = 1;
        SECTION("Test section 1") {
          x = x + 1;
          REQUIRE(x == 2);
        }
        SECTION("Test section 2") {
          REQUIRE(x == 1);
        }
      }
    CPP
    system ENV.cxx, "test.cpp", "-std=c++14", "-L#{lib}", "-lCatch2Main", "-lCatch2", "-o", "test"
    system "./test"
  end
end
