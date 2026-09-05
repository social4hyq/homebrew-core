class UnorderedDense < Formula
  desc "Hashmap and hashset based on robin-hood backward shift deletion"
  homepage "https://github.com/martinus/unordered_dense"
  url "https://github.com/martinus/unordered_dense/archive/refs/tags/v4.11.0.tar.gz"
  sha256 "a232f7433b45872d43e4dc74a25cbd58effc0be76e3d704b34e5de3c637eed77"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1c2c56a2eeedccf262f521812289c533a97787eabe2a1655e33f9beb21192e13"
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
