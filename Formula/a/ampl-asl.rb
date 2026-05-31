class AmplAsl < Formula
  desc "AMPL Solver Library"
  homepage "https://ampl.com/"
  url "https://github.com/ampl/asl/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "57b767161fd95869757daa0761d9b19fa39ad5de4315f95a3c0dff08b0d4c4f2"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aaac9ea6c74e9e411f55207afa683805f69d0e14f9d102cd842d53880586d50f"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DBUILD_SHARED_LIBS=ON
    ]
    args << "-DUSE_LTO=OFF" if OS.linux?
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <stdlib.h>
      #include "asl/asl.h"

      int main() {
          void* asl_instance = malloc(sizeof(void));
          free(asl_instance);
          return 0;
      }
    C

    system ENV.cc, "test.c", "-o", "test", "-I#{include}/asl", "-L#{lib}", "-lasl"
    system "./test"
  end
end
