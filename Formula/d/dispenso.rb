class Dispenso < Formula
  desc "High-performance C++ library for parallel programming"
  homepage "https://github.com/facebookincubator/dispenso"
  url "https://github.com/facebookincubator/dispenso/archive/refs/tags/v1.5.1.tar.gz"
  sha256 "e75b2a1bd428b2e9558ea99c03d266d2bf8881ba41689016e8c98052e1a0c17d"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c03b0d512b5a4083ddc778effb9444cc17135ff155190898663c9f67a7049d2e"
  end

  depends_on "cmake" => [:build, :test]

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DDISPENSO_BUILD_TESTS=OFF",
                    "-DDISPENSO_BUILD_BENCHMARKS=OFF",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <dispenso/parallel_for.h>
      #include <atomic>
      #include <cstdlib>

      int main() {
          std::atomic<int> sum(0);
          dispenso::parallel_for(0, 100, [&sum](int i) {
              sum += i + 1;
          });
          return sum.load() == 5050 ? EXIT_SUCCESS : EXIT_FAILURE;
      }
    CPP

    (testpath/"CMakeLists.txt").write <<~CMAKE
      cmake_minimum_required(VERSION 3.16)
      project(test_dispenso CXX)
      find_package(Dispenso REQUIRED)
      add_executable(test_dispenso test.cpp)
      target_link_libraries(test_dispenso Dispenso::dispenso)
    CMAKE

    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_CXX_STANDARD=14", *std_cmake_args
    system "cmake", "--build", "build"
    system "./build/test_dispenso"
  end
end
