class Libnotify < Formula
  desc "Library that sends desktop notifications to a notification daemon"
  homepage "https://gitlab.gnome.org/GNOME/libnotify"
  url "https://download.gnome.org/sources/libnotify/0.8/libnotify-0.8.8.tar.xz"
  sha256 "23420ef619dc2cb5aebad613f4823a2fa41c07e5a1d05628d40f6ec4b35bfddd"
  license "LGPL-2.1-or-later"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "52e08373b3fd243bca233c3ac422b0e1da96bfce488259e728c905ff67d4e503"
  end

  depends_on "docbook-xsl" => :build
  depends_on "gobject-introspection" => :build
  depends_on "gtk-doc" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]

  depends_on "gdk-pixbuf"
  depends_on "glib"

  on_macos do
    depends_on "gettext"
  end

  def install
    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog"

    args = %w[
      -Dgtk_doc=false
      -Dman=false
      -Dtests=false
    ]

    system "meson", "setup", "build", *args, *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <libnotify/notify.h>

      int main(int argc, char *argv[]) {
        g_assert_true(notify_init("testapp"));
        return 0;
      }
    C

    flags = shell_output("pkgconf --cflags --libs libnotify").chomp.split
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
