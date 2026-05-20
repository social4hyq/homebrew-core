class Primesieve < Formula
  desc "Fast C/C++ prime number generator"
  homepage "https://github.com/kimwalisch/primesieve"
  url "https://github.com/kimwalisch/primesieve/archive/refs/tags/v12.14.tar.gz"
  sha256 "65cf173e11bc9aff1b189f2cd19c6b6c502c30e966876b5c5ef71e138f49c8c9"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e7688fbf63f3a665314c01132771deb50f2e45456ad388ad36dd4cd90533615f"
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
