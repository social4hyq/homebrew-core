class Editorconfig < Formula
  desc "Maintain consistent coding style between multiple editors"
  homepage "https://editorconfig.org/"
  url "https://github.com/editorconfig/editorconfig-core-c/archive/refs/tags/v0.12.11.tar.gz"
  sha256 "9d8b420b56a969ea3cf784861c72d26fa0e158fa1494d732df2c8a1480d36a5c"
  license "BSD-2-Clause"
  head "https://github.com/editorconfig/editorconfig-core-c.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8c20c9bc201c900680d22a793c7a1000fb21be4946d44ceb6a3a777d2cc952d0"
  end

  depends_on "cmake" => :build
  depends_on "pcre2"

  def install
    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_INSTALL_RPATH=#{rpath}", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system bin/"editorconfig", "--version"
  end
end
