class Libcbor < Formula
  desc "CBOR protocol implementation for C and others"
  homepage "https://github.com/PJK/libcbor"
  url "https://github.com/PJK/libcbor/archive/refs/tags/v0.14.0.tar.gz"
  sha256 "a8c1516e741562cf95aa4479c64916c3d4d2623e24fdc35e414e2320e7300aae"
  license "MIT"
  compatibility_version 2

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8aedfbc3bbe728800d05f65484e35b8d55559163c1efb8af01d4c71c0b8b3855"
  end

  depends_on "cmake" => :build

  def install
    args = %w[
      -DWITH_EXAMPLES=OFF
      -DBUILD_SHARED_LIBS=ON
    ]

    system "cmake", "-S", ".", "-B", "builddir", *args, *std_cmake_args
    system "cmake", "--build", "builddir"
    system "cmake", "--install", "builddir"
  end

  test do
    (testpath/"example.c").write <<~C
      #include "cbor.h"
      #include <stdio.h>

      int main() {
        printf("Hello from libcbor %s\\n", CBOR_VERSION);
        printf("Pretty-printer support: %s\\n", CBOR_PRETTY_PRINTER ? "yes" : "no");
        printf("Buffer growth factor: %f\\n", (float) CBOR_BUFFER_GROWTH);
      }
    C

    system ENV.cc, "-std=c99", "example.c", "-o", "test", "-L#{lib}", "-lcbor"
    system "./test"
  end
end
