class Gtkmm < Formula
  desc "C++ interfaces for GTK+ and GNOME"
  homepage "https://www.gtkmm.org/"
  url "https://download.gnome.org/sources/gtkmm/2.24/gtkmm-2.24.5.tar.xz"
  sha256 "0680a53b7bf90b4e4bf444d1d89e6df41c777e0bacc96e9c09fc4dd2f5fe6b72"
  license "LGPL-2.1-or-later"
  revision 9

  livecheck do
    url :stable
    regex(/gtkmm[._-]v?(2\.([0-8]\d*?)?[02468](?:\.\d+)*?)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "44a52805beed821bd71a49a50810c4ac104849f2211b8bf4ee5cf330dbb54b07"
  end

  deprecate! date: "2026-05-22", because: :unmaintained
  disable! date: "2027-05-22", because: :unmaintained

  depends_on "pkgconf" => [:build, :test]

  depends_on "atkmm@2.28"
  depends_on "cairomm@1.14"
  depends_on "gdk-pixbuf"
  depends_on "glib"
  depends_on "glibmm@2.66"
  depends_on "gtk+"
  depends_on "libsigc++@2"
  depends_on "pangomm@2.46"

  on_macos do
    depends_on "at-spi2-core"
    depends_on "cairo"
    depends_on "gettext"
    depends_on "harfbuzz"
    depends_on "pango"
  end

  def install
    ENV.cxx11
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <gtkmm.h>

      int main(int argc, char *argv[]) {
        Gtk::Label label("Hello World!");
        return 0;
      }
    CPP

    flags = shell_output("pkgconf --cflags --libs gtkmm-2.4").chomp.split
    system ENV.cxx, "-std=c++11", "test.cpp", "-o", "test", *flags
    system "./test"
  end
end
