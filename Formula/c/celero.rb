class Celero < Formula
  desc "C++ Benchmark Authoring Library/Framework"
  homepage "https://github.com/DigitalInBlue/Celero"
  url "https://github.com/DigitalInBlue/Celero/archive/refs/tags/v2.10.0.tar.gz"
  sha256 "166f73a1f450396238074c7444e3295082bdda875355c62e1863af12a83be8fa"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f8da42724d235a5be0488bec6563f0fa4ca64da18589becfc5629bfa2b748603"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DCELERO_COMPILE_DYNAMIC_LIBRARIES=ON
      -DCELERO_ENABLE_EXPERIMENTS=OFF
      -DCELERO_ENABLE_TESTS=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <celero/Celero.h>
      #include <chrono>
      #include <thread>

      CELERO_MAIN

      BASELINE(DemoSleep, Baseline, 60, 1) {
        std::this_thread::sleep_for(std::chrono::microseconds(10000));
      }
      BENCHMARK(DemoSleep, HalfBaseline, 60, 1) {
        std::this_thread::sleep_for(std::chrono::microseconds(5000));
      }
      BENCHMARK(DemoSleep, TwiceBaseline, 60, 1) {
        std::this_thread::sleep_for(std::chrono::microseconds(20000));
      }
    CPP
    system ENV.cxx, "-std=c++14", "test.cpp", "-L#{lib}", "-lcelero", "-o", "test"
    system "./test"
  end
end
