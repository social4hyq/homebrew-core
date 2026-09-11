class CmakeDocs < Formula
  desc "Documentation for CMake"
  homepage "https://www.cmake.org/"
  url "https://github.com/Kitware/CMake/releases/download/v4.4.3/cmake-4.4.3.tar.gz"
  mirror "http://fresh-center.net/linux/misc/cmake-4.4.3.tar.gz"
  mirror "http://fresh-center.net/linux/misc/legacy/cmake-4.4.3.tar.gz"
  sha256 "c46400618b4f1f2b43507f24fb22f3ae830c3416cf23b776e16e1d413aa892f0"
  license "BSD-3-Clause"
  revision 1
  head "https://gitlab.kitware.com/cmake/cmake.git", branch: "master"

  livecheck do
    formula "cmake"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fd5ba0967bcbc383ce41f5c8114879d2be9c8ec99946e15c3128366304302602"
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
