class Crc32c < Formula
  desc "Implementation of CRC32C with CPU-specific acceleration"
  homepage "https://github.com/google/crc32c"
  url "https://github.com/google/crc32c/archive/refs/tags/1.1.2.tar.gz"
  sha256 "ac07840513072b7fcebda6e821068aa04889018f24e10e46181068fb214d7e56"
  license "BSD-3-Clause"
  head "https://github.com/google/crc32c.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a26c16c17dce1dbb85c7384016c71ad17ce8075cb1008bcd7decd696233ae12c"
  end

  depends_on "cmake" => :build

  def install
    # Backport support for CMake 4. Remove on the next release when inreplace fails
    # https://github.com/google/crc32c/commit/2bbb3be42e20a0e6c0f7b39dc07dc863d9ffbc07
    inreplace "CMakeLists.txt", /(cmake_minimum_required\(VERSION) 3\.1\)/, "\\1 3.16)" if build.stable?

    args = %w[
      -DCRC32C_BUILD_TESTS=0
      -DCRC32C_BUILD_BENCHMARKS=0
      -DCRC32C_USE_GLOG=0
    ]

    system "cmake", "-S", ".", "-B", "build-static", *args, *std_cmake_args
    system "cmake", "--build", "build-static"
    system "cmake", "--install", "build-static"

    system "cmake", "-S", ".", "-B", "build-shared", "-DBUILD_SHARED_LIBS=ON", *args, *std_cmake_args
    system "cmake", "--build", "build-shared"
    system "cmake", "--install", "build-shared"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <cassert>
      #include <crc32c/crc32c.h>
      #include <cstdint>
      #include <string>

      int main()
      {
        std::uint32_t expected = 0xc99465aa;
        std::uint32_t result = crc32c::Crc32c(std::string("hello world"));
        assert(result == expected);
        return 0;
      }
    CPP

    system ENV.cxx, "test.cpp", "-I#{include}", "-L#{lib}", "-lcrc32c", "-std=c++11", "-o", "test"
    system "./test"
  end
end
