class Libheinz < Formula
  desc "C++ base library of Heinz Maier-Leibnitz Zentrum"
  homepage "https://jugit.fz-juelich.de/mlz/libheinz"
  url "https://jugit.fz-juelich.de/mlz/libheinz/-/archive/v4.0.0/libheinz-v4.0.0.tar.bz2"
  sha256 "cc78e7701a70bc4e476f8968d1c15030b26126da578e099994724fb7f1a3a5fa"
  license "0BSD"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e15e3faed2671cbaee60ee8302a3d9b0cf19244a5b941101422bc186d16cfd68"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <heinz/Vectors3D.h>
      #include <iostream>

      int main() {
        R3 vector(1.0, 2.0, 3.0);
        if (vector.x() == 1.0 && vector.y() == 2.0 && vector.z() == 3.0) {
          std::cout << "Success" << std::endl;
          return 0;
        }
        return 1;
      }
    CPP

    system ENV.cxx, "-std=c++17", "test.cpp", "-I#{include}", "-o", "test"
    system "./test"
  end
end
