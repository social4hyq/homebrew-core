class Qpdf < Formula
  desc "Tools for and transforming and inspecting PDF files"
  homepage "https://github.com/qpdf/qpdf"
  url "https://github.com/qpdf/qpdf/releases/download/v12.3.2/qpdf-12.3.2.tar.gz"
  sha256 "6cba2f9f2cd887d905faeb99e0e51a307b217920d1bbf3e9cfbb2e8178a2deda"
  license "Apache-2.0"
  revision 1
  compatibility_version 1

  no_autobump! because: "newer version requires c++20 support"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b7e92fdfbe6be3ffdf991a3e4076361999dd68f22cfd127592bf3cad67590795"
  end

  depends_on "cmake" => :build
  depends_on "jpeg-turbo"
  depends_on "openssl@3"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DUSE_IMPLICIT_CRYPTO=0",
                    "-DREQUIRE_CRYPTO_OPENSSL=1",
                    "-DCMAKE_INSTALL_RPATH=#{rpath}",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system bin/"qpdf", "--version"
  end
end
