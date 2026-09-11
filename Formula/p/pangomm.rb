class Pangomm < Formula
  desc "C++ interface to Pango"
  homepage "https://www.gtk.org/docs/architecture/pango"
  url "https://download.gnome.org/sources/pangomm/2.56/pangomm-2.56.2.tar.xz"
  sha256 "f1e984c85a85b6a0e61616366521f51dd8282a072bb45d15b5084762b62f4c0e"
  license "LGPL-2.1-only"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5e318c1c5264173e19fd52cac52411339b88ce9770b7d28d83560832fc67fd78"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]

  depends_on "cairomm"
  depends_on "glib"
  depends_on "glibmm"
  depends_on "libsigc++"
  depends_on "pango"

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <pangomm.h>
      int main(int argc, char *argv[])
      {
        Pango::FontDescription fd;
        return 0;
      }
    CPP

    pkgconf_flags = shell_output("pkgconf --cflags --libs pangomm-2.48").chomp.split
    system ENV.cxx, "-std=c++17", "test.cpp", *pkgconf_flags, "-o", "test"
    system "./test"
  end
end
