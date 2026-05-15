class Pystring < Formula
  desc "Collection of C++ functions for the interface of Python's string class methods"
  homepage "https://github.com/imageworks/pystring"
  url "https://github.com/imageworks/pystring/archive/refs/tags/v1.1.5.tar.gz"
  sha256 "63c30c251b8017c897bd923826f400aee1d6e4f1c22ffbbd2104f150522a2040"
  license "BSD-3-Clause"
  head "https://github.com/imageworks/pystring.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "21296891b862287c54e0170c7d115e96843ec6075d1e10793f743639b6fe603c"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    include.install "pystring.h"
    pkgshare.install "test.cpp", "unittest.h"
  end

  test do
    system ENV.cxx, "-std=c++11", pkgshare/"test.cpp", "-I#{include}", "-I#{pkgshare}", "-L#{lib}",
                    "-lpystring", "-o", "test"
    system "./test"
  end
end
