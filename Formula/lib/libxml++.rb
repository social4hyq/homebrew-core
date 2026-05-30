class Libxmlxx < Formula
  desc "C++ wrapper for libxml"
  homepage "https://libxmlplusplus.sourceforge.net/"
  url "https://github.com/libxmlplusplus/libxmlplusplus/releases/download/2.42.4/libxml++-2.42.4.tar.xz"
  sha256 "82c7bb4f20a227bba174158be475c1017f650b276f9268923c6601b5a545838f"
  license "LGPL-2.1-or-later"

  livecheck do
    url :stable
    regex(/^v?(2\.([0-8]\d*?)?[02468](?:\.\d+)*?)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ec5f3b335bbaece2b011e769e219b7aba93f2c4c846a3453880a40fbf8fcdea2"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "glibmm@2.66"

  uses_from_macos "libxml2"

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <libxml++/libxml++.h>

      int main(int argc, char *argv[])
      {
         xmlpp::Document document;
         document.set_internal_subset("homebrew", "", "https://www.brew.sh/xml/test.dtd");
         xmlpp::Element *rootnode = document.create_root_node("homebrew");
         return 0;
      }
    CPP

    flags = shell_output("pkgconf --cflags --libs libxml++-2.6").chomp.split
    system ENV.cxx, "-std=c++11", "test.cpp", "-o", "test", *flags
    system "./test"
  end
end
