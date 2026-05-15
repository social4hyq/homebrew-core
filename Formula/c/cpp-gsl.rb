class CppGsl < Formula
  desc "Microsoft's C++ Guidelines Support Library"
  homepage "https://github.com/Microsoft/GSL"
  url "https://github.com/Microsoft/GSL/archive/refs/tags/v4.2.1.tar.gz"
  sha256 "d959f1cb8bbb9c94f033ae5db60eaf5f416be1baa744493c32585adca066fe1f"
  license "MIT"
  head "https://github.com/Microsoft/GSL.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ad77b067333a73058e7c353212c0356cb08846baebfde7cb1ca0f5f7e357b862"
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
