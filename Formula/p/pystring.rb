class Pystring < Formula
  desc "Collection of C++ functions for the interface of Python's string class methods"
  homepage "https://github.com/imageworks/pystring"
  url "https://github.com/imageworks/pystring/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "020a603a757ba1e429f4b1ea6feb3afbe0fb34bcafa355032e1f1b8a0019d198"
  license "BSD-3-Clause"
  head "https://github.com/imageworks/pystring.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "59b2f84bd285eeb0c833d740141abb6b41ebb4a86ce8724cc0f37d5f038a45ca"
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
