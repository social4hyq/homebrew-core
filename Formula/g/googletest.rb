class Googletest < Formula
  desc "Google Testing and Mocking Framework"
  homepage "https://google.github.io/googletest/"
  url "https://github.com/google/googletest/archive/refs/tags/v1.18.0.tar.gz"
  sha256 "6e3191c1455468b3fc35a417fb565c1c5071aee1b7e7f85e30cf48a98d37d8b5"
  license "BSD-3-Clause"
  revision 1
  head "https://github.com/google/googletest.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4fa1cb0b2bf044548c8a7fa9e42b1ca0f42da11fa3556f9bb9702cdb32e898cd"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DCMAKE_CXX_STANDARD=17",
                    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # for use case like `#include "googletest/googletest/src/gtest-all.cc"`
    (include/"googlemock/googlemock/src").install Dir["googlemock/src/*"]
    (include/"googletest/googletest/src").install Dir["googletest/src/*"]
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <string>
      #include <string_view>
      #include <vector>
      #include <gtest/gtest.h>
      #include <gtest/gtest-death-test.h>
      #include "gmock/gmock.h"

      TEST(Simple, Boolean)
      {
        ASSERT_TRUE(true);
      }
      TEST(Simple, Cpp17StringView)
      {
        const char* c = "test";
        std::string s{c};
        std::string_view sv{s};
        std::vector<std::string_view> vsv{sv};
        EXPECT_EQ(sv, s);
        EXPECT_EQ(sv, s.c_str());
        EXPECT_EQ(sv, "test");
        EXPECT_THAT(vsv, testing::ElementsAre("test"));
      }
    CPP
    system ENV.cxx, "test.cpp", "-std=c++17", "-L#{lib}", "-lgtest", "-lgtest_main", "-pthread", "-o", "test"
    system "./test"
  end
end
