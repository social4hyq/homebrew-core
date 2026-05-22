class Cppad < Formula
  desc "Differentiation of C++ Algorithms"
  homepage "https://cppad.readthedocs.io/latest/"
  url "https://github.com/coin-or/CppAD/archive/refs/tags/20260000.0.tar.gz"
  sha256 "41ec617bb1e4163da381aaa5083a152e033631e9b5e135ccdc3466aaa1dc9001"
  license "EPL-2.0"
  version_scheme 1
  head "https://github.com/coin-or/CppAD.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "49321e9723ec21a1b0d204b64b936725d3e101ecbfaffda991e08424a4594312"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build

  def install
    ENV.cxx11

    system "cmake", "-S", ".", "-B", "build", "-Dcppad_prefix=#{prefix}", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    pkgshare.install "example"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <cassert>
      #include <cppad/local/temp_file.hpp>
      #include <cppad/utility/thread_alloc.hpp>

      int main(void) {
        extern bool acos(void);
        bool ok = acos();
        assert(ok);
        return static_cast<int>(!ok);
      }
    CPP

    system ENV.cxx, "#{pkgshare}/example/general/acos.cpp", "-std=c++11", "-I#{include}",
                    "-L#{lib}", "-lcppad_lib",
                    "test.cpp", "-o", "test"
    system "./test"
  end
end
