class Lmfit < Formula
  desc "C library for Levenberg-Marquardt minimization and least-squares fitting"
  homepage "https://jugit.fz-juelich.de/mlz/lmfit"
  url "https://jugit.fz-juelich.de/mlz/lmfit/-/archive/v11.0/lmfit-v11.0.tar.bz2"
  sha256 "5289b1264f82cd9a62d445848dc17d2fce1cdc0079b24594f52d87c12e1ac716"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3a7793b5dabb25806ed468e794157b0906b6d93840ee9b481b8302b403003d49"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    pkgshare.install "demo/curve1.c"
  end

  test do
    system ENV.cc, pkgshare/"curve1.c", "-I#{include}", "-L#{lib}", "-llmfit", "-o", "test"
    assert_match "converged  (the relative error in the sum of squares is at most tol)", shell_output("./test")
  end
end
