class Libgnt < Formula
  desc "NCurses toolkit for creating text-mode graphical user interfaces"
  homepage "https://pidgin.im/"
  url "https://downloads.sourceforge.net/project/pidgin/libgnt/2.14.4/libgnt-2.14.4-dev.tar.xz"
  sha256 "195933a9a731d3575791b881ba5cc0ad2a715e1e9c4c23ccaaa2a17e164c96ec"
  license "GPL-2.0-or-later"
  revision 1

  livecheck do
    url "https://sourceforge.net/projects/pidgin/rss?path=/libgnt"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "323960633d79f1c72858aaf909a998a60ba8e7ea8c33ff44c41ebd8376fbad74"
  end

  depends_on "gtk-doc" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build

  depends_on "glib"
  depends_on "ncurses"

  uses_from_macos "libxml2"

  on_macos do
    depends_on "gettext"
  end

  def install
    ENV["XML_CATALOG_FILES"] = etc/"xml/catalog"

    # upstream bug report on this workaround, https://issues.imfreedom.org/issue/LIBGNT-15
    inreplace "meson.build", "ncurses_sys_prefix = '/usr'",
                             "ncurses_sys_prefix = '#{Formula["ncurses"].opt_prefix}'"

    system "meson", "setup", "build", "-Dpython2=false", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <gnt/gnt.h>

      int main() {
          gnt_init();
          gnt_quit();

          return 0;
      }
    C

    flags = [
      "-I#{Formula["glib"].opt_include}/glib-2.0",
      "-I#{Formula["glib"].opt_lib}/glib-2.0/include",
      "-I#{include}",
      "-L#{lib}",
      "-L#{Formula["glib"].opt_lib}",
      "-lgnt",
      "-lglib-2.0",
    ]
    system ENV.cc, "test.c", *flags, "-o", "test"
    system "./test"
  end
end
