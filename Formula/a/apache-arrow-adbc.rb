class ApacheArrowAdbc < Formula
  desc "Cross-language, Arrow-native database access"
  homepage "https://arrow.apache.org/adbc"
  url "https://www.apache.org/dyn/closer.lua?path=arrow/apache-arrow-adbc-24/apache-arrow-adbc-24.tar.gz"
  sha256 "2b4b420937f62f7ae56f46dbd6951a5e4ef0da43158080a58cb44cdd09a8b2e0"
  license "Apache-2.0"
  head "https://github.com/apache/arrow-adbc.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c0c67aab4fe6ed9ca87d21cc91aace98554d4e431d4b9bcf2bf3200a79017fef"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build

  def install
    args = %w[
      -DADBC_BUILD_STATIC=OFF
      -DADBC_BUILD_SHARED=ON
      -DADBC_DRIVER_MANAGER=ON
      -DADBC_DRIVER_POSTGRESQL=OFF
      -DADBC_DRIVER_SQLITE=OFF
    ]
    system "cmake", "-S", "c", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include "arrow-adbc/adbc.h"
      int main(void) {
        struct AdbcError error;
        return 0;
      }
    CPP
    system ENV.cxx, "test.cpp", "-std=c++17", "-I#{include}", "-L#{lib}", "-ladbc_driver_manager", "-o", "test"
    system "./test"
  end
end
