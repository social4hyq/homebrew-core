class CppGsl < Formula
  desc "Microsoft's C++ Guidelines Support Library"
  homepage "https://github.com/Microsoft/GSL"
  url "https://github.com/Microsoft/GSL/archive/refs/tags/v5.0.0.tar.gz"
  sha256 "e646da6ac00a885cfae33dc935e52bb42bd1d05e41b8437cbc25ca3d74930f35"
  license "MIT"
  revision 1
  head "https://github.com/Microsoft/GSL.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "996a3a85fed450ca638d705bffd878c0b4ff4f9f7d696d851a494bc3e86e2326"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-DGSL_TEST=false", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <gsl/gsl>
      int main() {
        gsl::span<int> z;
        return 0;
      }
    CPP

    system ENV.cxx, "test.cpp", "-o", "test", "-std=c++14"
    system "./test"
  end
end
