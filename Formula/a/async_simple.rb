class AsyncSimple < Formula
  desc "Simple, light-weight and easy-to-use asynchronous components"
  homepage "https://github.com/alibaba/async_simple"
  url "https://github.com/alibaba/async_simple/archive/refs/tags/1.4.tar.gz"
  sha256 "6188f7a5f4211754fee758dfebf73759b74ce78c208719b5cc37d5ab4775d550"
  license "Apache-2.0"
  head "https://github.com/alibaba/async_simple.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c8b1f4ebde2a8be6fa76dc5713c8a9b79ba94037dd3f911c262466336fcf3b56"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DCMAKE_CXX_STANDARD=20
      -DBUILD_GMOCK=OFF
      -DBUILD_GTEST=OFF
      -DINSTALL_GTEST=OFF
      -DASYNC_SIMPLE_BUILD_DEMO_EXAMPL=OFF
      -DASYNC_SIMPLE_ENABLE_TESTS=OFF
    ]

    system "cmake", "-S", ".", "-B", "builddir", *args, *std_cmake_args
    system "cmake", "--build", "builddir"
    system "cmake", "--install", "builddir"
  end

  test do
    (testpath / "test.cpp").write <<~CPP
      #include <algorithm>
      #include <async_simple/coro/Lazy.h>
      #include <async_simple/coro/SyncAwait.h>
      #include <iostream>
      #include <string>
      #include <vector>

      using namespace async_simple::coro;

      using Texts = std::vector<std::string>;

      Lazy<int> CountLineChar(const std::string& line, char c) {
        auto ret = std::count(line.begin(), line.end(), c);
        co_return static_cast<int>(ret);
      }

      auto main() -> int {
        auto num = syncAwait(CountLineChar("axxxax", 'x'));
        std::cout << num << std::endl;
      }
    CPP
    system ENV.cxx, "test.cpp", "-std=c++20", "-L#{lib}", "-lasync_simple", "-o", "test"
    assert_equal "4", shell_output("./test").chomp
  end
end
