class Qthreads < Formula
  desc "Lightweight locality-aware user-level threading runtime"
  homepage "https://www.sandia.gov/qthreads/"
  url "https://github.com/sandialabs/qthreads/archive/refs/tags/1.23.tar.gz"
  sha256 "fb5c3efc022231245f7b1894a82eac1fd020c5f90000bb4770e64e2c1ad77913"
  license "BSD-3-Clause"
  head "https://github.com/sandialabs/qthreads.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c02496188592267f7dc2007e6082256c68b639caa423cfd35bf505cff70b91f0"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    pkgshare.install "userguide/examples"
    doc.install "userguide"
  end

  test do
    system ENV.cc, pkgshare/"examples/hello_world.c", "-o", "hello", "-I#{include}", "-L#{lib}", "-lqthread"
    assert_equal "Hello, world!", shell_output("./hello").chomp
  end
end
