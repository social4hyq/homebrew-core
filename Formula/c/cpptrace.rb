class Cpptrace < Formula
  desc "Simple, portable, and self-contained stacktrace library for C++11 and newer"
  homepage "https://github.com/jeremy-rifkin/cpptrace"
  url "https://github.com/jeremy-rifkin/cpptrace/archive/refs/tags/v1.0.4.tar.gz"
  sha256 "5c9f5b301e903714a4d01f1057b9543fa540f7bfcc5e3f8bd1748e652e24f9ea"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "08931fc40fdf79474bbe7c2222ace9c8375c401e4879bf8ffe899fec7fd833d5"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "dwarfutils"
  depends_on "zstd"

  def install
    args = %W[
      -DBUILD_SHARED_LIBS=ON
      -DCMAKE_INSTALL_RPATH=#{rpath}
      -DCPPTRACE_DEMANGLE_WITH_CXXABI=ON
      -DCPPTRACE_FIND_LIBDWARF_WITH_PKGCONFIG=ON
      -DCPPTRACE_GET_SYMBOLS_WITH_LIBDWARF=ON
      -DCPPTRACE_UNWIND_WITH_EXECINFO=ON
      -DCPPTRACE_USE_EXTERNAL_GTEST=ON
      -DCPPTRACE_USE_EXTERNAL_LIBDWARF=ON
      -DCPPTRACE_USE_EXTERNAL_ZSTD=ON
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <cpptrace/cpptrace.hpp>

      int main() {
        cpptrace::generate_trace().print();
        return 0;
      }
    CPP
    system ENV.cxx, "test.cpp", "-std=c++11", "-I#{include}", "-L#{lib}", "-o", "test", "-lcpptrace"
    system "./test"
  end
end
