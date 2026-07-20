class Primesieve < Formula
  desc "Fast C/C++ prime number generator"
  homepage "https://github.com/kimwalisch/primesieve"
  url "https://github.com/kimwalisch/primesieve/archive/refs/tags/v12.15.tar.gz"
  sha256 "acaafd94cc30dbeef4808e682d0cb096c05d25f74eda5bacecefd323f697833f"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fdeef2f0831d6ee3949a7feada40c2cf5792c359a0468c6cc396396fd329e287"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_INSTALL_RPATH=#{rpath}", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system bin/"primesieve", "100", "--count", "--print"
  end
end
