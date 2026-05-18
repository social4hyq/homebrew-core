class Nlopt < Formula
  desc "Free/open-source library for nonlinear optimization"
  homepage "https://nlopt.readthedocs.io/"
  url "https://github.com/stevengj/nlopt/archive/refs/tags/v2.10.1.tar.gz"
  sha256 "30d13ce16da119db3e987784f7864e35a562ec62c186352fae55cd003e6c58ff"
  license "MIT"
  head "https://github.com/stevengj/nlopt.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "94056417721c1840716a520af0b88230f920eb8924ab9c3332a7e9965b7291e4"
  end

  depends_on "cmake" => [:build, :test]

  def install
    args = %w[
      -DNLOPT_GUILE=OFF
      -DNLOPT_MATLAB=OFF
      -DNLOPT_OCTAVE=OFF
      -DNLOPT_PYTHON=OFF
      -DNLOPT_SWIG=OFF
      -DNLOPT_TESTS=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    pkgshare.install "test/box.c"

    # Avoid rebuilding dependents that hard-code the prefix.
    inreplace lib/"pkgconfig/nlopt.pc", prefix, opt_prefix
  end

  test do
    (testpath/"CMakeLists.txt").write <<~CMAKE
      cmake_minimum_required(VERSION 4.0)
      project(box C)
      find_package(NLopt REQUIRED)
      add_executable(box "#{pkgshare}/box.c")
      target_link_libraries(box NLopt::nlopt)
    CMAKE

    system "cmake", "-S", ".", "-B", "build"
    system "cmake", "--build", "build"
    assert_match "found", shell_output("./build/box")
  end
end
