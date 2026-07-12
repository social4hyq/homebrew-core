class Libzim < Formula
  desc "Reference implementation of the ZIM specification"
  homepage "https://github.com/openzim/libzim"
  url "https://github.com/openzim/libzim/archive/refs/tags/9.8.1.tar.gz"
  sha256 "718d82930949de8eae14809de1af92414071811ba68c91e9ad0abb1fe3287799"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "02a6b4e74b19aae04c5fed59404203b8cdcf054623013025ad28abd46d7ab2f7"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build

  depends_on "icu4c@78"
  depends_on "xapian"
  depends_on "xz"
  depends_on "zstd"

  uses_from_macos "python" => :build

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      #include <zim/version.h>
      int main(void) {
        zim::printVersions(); // first line should print "libzim <version>"
        return 0;
      }
    CPP

    system ENV.cxx, "test.cpp", "-L#{lib}", "-lzim", "-o", "test", "-std=c++11"
    assert_match "libzim #{version}", shell_output("./test")
  end
end
