class UnorderedDense < Formula
  desc "Hashmap and hashset based on robin-hood backward shift deletion"
  homepage "https://github.com/martinus/unordered_dense"
  url "https://github.com/martinus/unordered_dense/archive/refs/tags/v4.9.2.tar.gz"
  sha256 "abe3b267cbec3094bd7ca84a9990d7723a8d3dda141e08c67e295e3175f6ee28"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fa3ef6fd5d97a04132eae7e1c3d84db2577660235d38569043449dc72e61ed05"
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
