class UnorderedDense < Formula
  desc "Hashmap and hashset based on robin-hood backward shift deletion"
  homepage "https://github.com/martinus/unordered_dense"
  url "https://github.com/martinus/unordered_dense/archive/refs/tags/v4.8.1.tar.gz"
  sha256 "9f7202ec6d8353932ef865d33f5872e4b7a1356e9032da7cd09c3a0c5bb2b7de"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "96d1788efbca1246c7ac2d16c0c5229d71cc3a8babf501704e922c5ecdee3533"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    pkgshare.install "example"
  end

  test do
    cp pkgshare/"example/main.cpp", testpath
    system ENV.cxx, "-std=c++17", "main.cpp", "-o", "test"
    system "./test"
  end
end
