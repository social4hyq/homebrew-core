class Imath < Formula
  desc "Library of 2D and 3D vector, matrix, and math operations"
  homepage "https://imath.readthedocs.io/en/latest/"
  url "https://github.com/AcademySoftwareFoundation/Imath/archive/refs/tags/v3.2.3.tar.gz"
  sha256 "e10c12b3f21f45bf08e09d4215d9c7691368d747beebd840de0b6fefed2df9f8"
  license "BSD-3-Clause"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9751604c862989c8317eebbe8255acfd398eb2379cc1a482336dff2383acc75d"
  end

  depends_on "cmake" => :build

  # These used to be provided by `ilmbase`
  link_overwrite "lib/libImath.dylib"
  link_overwrite "lib/libImath.so"

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~'CPP'
      #include <ImathRoots.h>
      #include <algorithm>
      #include <iostream>

      int main(int argc, char *argv[])
      {
        double x[2] = {0.0, 0.0};
        int n = IMATH_NAMESPACE::solveQuadratic(1.0, 3.0, 2.0, x);

        if (x[0] > x[1])
          std::swap(x[0], x[1]);

        std::cout << n << ", " << x[0] << ", " << x[1] << "\n";
      }
    CPP
    system ENV.cxx, "-std=c++11", "-I#{include}/Imath", "-o", testpath/"test", "test.cpp"
    assert_equal "2, -2, -1\n", shell_output("./test")
  end
end
