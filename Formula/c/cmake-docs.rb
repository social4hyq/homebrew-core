class CmakeDocs < Formula
  desc "Documentation for CMake"
  homepage "https://www.cmake.org/"
  url "https://github.com/Kitware/CMake/releases/download/v4.4.0/cmake-4.4.0.tar.gz"
  mirror "http://fresh-center.net/linux/misc/cmake-4.4.0.tar.gz"
  mirror "http://fresh-center.net/linux/misc/legacy/cmake-4.4.0.tar.gz"
  sha256 "65757f442fdd242e27f1728fc26dc0cba4164f7a0791a5c788631c00080369bc"
  license "BSD-3-Clause"
  head "https://gitlab.kitware.com/cmake/cmake.git", branch: "master"

  livecheck do
    formula "cmake"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "10c2b6653af7f02a5758d6308353ff1d32122641f9dc8a81b1449e8d38632d3c"
  end

  depends_on "cmake" => :build
  depends_on "sphinx-doc" => :build

  def install
    args = %w[
      -DCMAKE_DOC_DIR=share/doc/cmake
      -DCMAKE_MAN_DIR=share/man
      -DSPHINX_MAN=ON
      -DSPHINX_HTML=ON
    ]
    system "cmake", "-S", "Utilities/Sphinx", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    assert_path_exists share/"doc/cmake/html"
    assert_path_exists man
  end
end
