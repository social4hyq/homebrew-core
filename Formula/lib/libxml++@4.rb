class LibxmlxxAT4 < Formula
  desc "C++ wrapper for libxml"
  homepage "https://libxmlplusplus.github.io/libxmlplusplus/"
  url "https://github.com/libxmlplusplus/libxmlplusplus/releases/download/4.4.1/libxml++-4.4.1.tar.xz"
  sha256 "110df9efc4cbc6b2e83a25796075ba7ca4934951a29e1c34e1962b2c1b205614"
  license "LGPL-2.1-or-later"

  livecheck do
    url :stable
    regex(/^v?(4\.([0-8]\d*?)?[02468](?:\.\d+)*?)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6f03f10813c8f86139e345bb5f0dbedca35d8d7a48c3b95cfa8481648fdf3cc0"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "glibmm"

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
    command = "#{Formula["pkgconf"].opt_bin}/pkgconf --cflags --libs libxml++-4.0"
    flags = shell_output(command).strip.split
    system ENV.cxx, "-std=c++17", "test.cpp", "-o", "test", *flags
    system "./test"
  end
end
