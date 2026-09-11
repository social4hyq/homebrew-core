class Beagle < Formula
  desc "Evaluate the likelihood of sequence evolution on trees"
  homepage "https://github.com/beagle-dev/beagle-lib"
  url "https://github.com/beagle-dev/beagle-lib/archive/refs/tags/v4.0.1.tar.gz"
  sha256 "9d258cd9bedd86d7c28b91587acd1132f4e01d4f095c657ad4dc93bd83d4f120"
  license "MIT"
  revision 1

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2bcfdb4172c01d8c0909b918baa1364a73a12937c345673168e59ccb0f6b57e9"
  end

  depends_on "cmake" => :build
  depends_on "openjdk" => [:build, :test]

  def install
    # Avoid building Linux bottle with `-march=native`. Need to enable SSE4.1 for _mm_dp_pd
    # Issue ref: https://github.com/beagle-dev/beagle-lib/issues/189
    inreplace "CMakeLists.txt", "-march=native", "-msse4.1" if OS.linux? && build.bottle?

    ENV["JAVA_HOME"] = Language::Java.java_home
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    pkgshare.install "examples/tinytest/tinytest.cpp"
  end

  test do
    if OS.mac? && Hardware::CPU.arm? && Hardware::CPU.virtualized?
      # OpenCL is not supported on virtualized arm64 macOS which breaks all Beagle functionality
      (testpath/"test.cpp").write <<~CPP
        #include <iostream>
        #include "libhmsbeagle/beagle.h"
        int main() {
          std::cout << beagleGetVersion();
          return 0;
        }
      CPP
      system ENV.cxx, "test.cpp", "-o", "test", "-I#{include}/libhmsbeagle-1", "-L#{lib}", "-lhmsbeagle"
      assert_match version.to_s, shell_output("./test")
    else
      system ENV.cxx, pkgshare/"tinytest.cpp", "-o", "test", "-I#{include}/libhmsbeagle-1", "-L#{lib}", "-lhmsbeagle"
      assert_match "sumLogL = -1498.", shell_output("./test")
    end

    (testpath/"T.java").write <<~JAVA
      class T {
        static { System.loadLibrary("hmsbeagle-jni"); }
        public static void main(String[] args) {}
      }
    JAVA
    system Formula["openjdk"].bin/"javac", "T.java"
    system Formula["openjdk"].bin/"java", "-Djava.library.path=#{lib}", "T"
  end
end
