class Libecpint < Formula
  desc "Library for the efficient evaluation of integrals over effective core potentials"
  homepage "https://github.com/robashaw/libecpint"
  url "https://github.com/robashaw/libecpint/archive/refs/tags/v1.0.7.tar.gz"
  sha256 "e9c60fddb2614f113ab59ec620799d961db73979845e6e637c4a6fb72aee51cc"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "98d8dc4c95f2e837e675e740349a15f43de543c73fc7ca5a78a5f80f1eec1762"
  end

  depends_on "cmake" => :build
  depends_on "libcerf"
  depends_on "pugixml"

  uses_from_macos "python" => :build

  def install
    # Fix the error: found '_dawson' in libcerf.3.0.dylib, declaration possibly missing 'extern "C"'
    # Issue ref: https://github.com/robashaw/libecpint/issues/65
    inreplace "src/CMakeLists.txt", "cerf::cerf", "cerf::cerfcpp"

    args = [
      "-DBUILD_SHARED_LIBS=ON",
      "-DLIBECPINT_USE_CERF=ON",
      "-DLIBECPINT_BUILD_TESTS=OFF",
      "-DPython_EXECUTABLE=#{which("python3")}",
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    pkgshare.install "tests/lib/api_test1/test1.cpp",
                     "tests/lib/api_test1/api_test1.output",
                     "include/testutil.hpp"
  end

  test do
    cp [pkgshare/"api_test1.output", pkgshare/"testutil.hpp"], testpath
    system ENV.cxx, "-std=c++11", pkgshare/"test1.cpp",
                    "-DHAS_PUGIXML", "-I#{include}/libecpint",
                    "-L#{lib}", "-lecpint", "-o", "test1"
    system "./test1"
  end
end
