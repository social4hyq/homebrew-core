class Pangomm < Formula
  desc "C++ interface to Pango"
  homepage "https://www.gtk.org/docs/architecture/pango"
  url "https://download.gnome.org/sources/pangomm/2.58/pangomm-2.58.0.tar.xz"
  sha256 "217514c1a65035c2fce6e69e33b0d92bafa2594cc474e995a4473441b10f3a33"
  license "LGPL-2.1-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "648f0fbac9b0b457dd884a505f709e08d2dfa28be415b24daca73535f7393350"
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
