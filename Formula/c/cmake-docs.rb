class CmakeDocs < Formula
  desc "Documentation for CMake"
  homepage "https://www.cmake.org/"
  url "https://github.com/Kitware/CMake/releases/download/v4.3.3/cmake-4.3.3.tar.gz"
  mirror "http://fresh-center.net/linux/misc/cmake-4.3.3.tar.gz"
  mirror "http://fresh-center.net/linux/misc/legacy/cmake-4.3.3.tar.gz"
  sha256 "cba4bb7a44edf2877bb6f059932896383babe435b3a8c3b5df48b4aa41c9bb85"
  license "BSD-3-Clause"
  head "https://gitlab.kitware.com/cmake/cmake.git", branch: "master"

  livecheck do
    formula "cmake"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cec81c9588113a18d999a7374a695e2c07c7a3179c4a0a3f223fcd3211e52789"
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
