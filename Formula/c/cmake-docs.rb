class CmakeDocs < Formula
  desc "Documentation for CMake"
  homepage "https://www.cmake.org/"
  url "https://github.com/Kitware/CMake/releases/download/v4.4.2/cmake-4.4.2.tar.gz"
  mirror "http://fresh-center.net/linux/misc/cmake-4.4.2.tar.gz"
  mirror "http://fresh-center.net/linux/misc/legacy/cmake-4.4.2.tar.gz"
  sha256 "1db9e61e60b6e0874c86386340b910382f3c5e75b9fbfb44d122063129a2789d"
  license "BSD-3-Clause"
  head "https://gitlab.kitware.com/cmake/cmake.git", branch: "master"

  livecheck do
    formula "cmake"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "12e1c374e9b84b80b9247e060e3663fbf225efe4e634914172b8e8a93fc9bc7a"
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
