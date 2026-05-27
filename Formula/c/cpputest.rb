class Cpputest < Formula
  desc "C /C++ based unit xUnit test framework"
  homepage "https://cpputest.github.io/"
  url "https://github.com/cpputest/cpputest/releases/download/v4.0/cpputest-4.0.tar.gz"
  sha256 "21c692105db15299b5529af81a11a7ad80397f92c122bd7bf1e4a4b0e85654f7"
  license "BSD-3-Clause"
  head "https://github.com/cpputest/cpputest.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dfd85b9345f7c16b82c3538b1b14faff6b4917a2c424aa4370ba792a4cc79255"
  end

  depends_on "cmake" => :build

  def install
    # Backport support for CMake 4. Remove in the next release
    # https://github.com/cpputest/cpputest/commit/fbb8526750aa370e642da7c21a98d6efdf7a3f37
    inreplace "CMakeLists.txt", /(cmake_minimum_required\(VERSION) 3\.1\)/, "\\1 3.8)" if build.stable?

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include "CppUTest/CommandLineTestRunner.h"

      TEST_GROUP(HomebrewTest)
      {
      };

      TEST(HomebrewTest, passing)
      {
        CHECK(true);
      }
      int main(int ac, char** av)
      {
        return CommandLineTestRunner::RunAllTests(ac, av);
      }
    CPP
    system ENV.cxx, "test.cpp", "-L#{lib}", "-lCppUTest", "-o", "test"
    assert_match "OK (1 tests", shell_output("./test")
  end
end
