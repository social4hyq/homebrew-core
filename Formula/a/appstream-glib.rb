class AppstreamGlib < Formula
  desc "Helper library for reading and writing AppStream metadata"
  homepage "https://github.com/hughsie/appstream-glib"
  url "https://github.com/hughsie/appstream-glib/archive/refs/tags/appstream_glib_0_8_4.tar.gz"
  sha256 "19798c8fbd2734554848817e52ef351d21253b1df9fff288b7cf91c10618415d"
  license "LGPL-2.1-or-later"
  revision 1

  livecheck do
    url :stable
    regex(/^appstream_glib[._-]v?(\d+(?:[._]\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag[regex, 1]&.tr("_", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8964f0a212325e3decb3f7ad7a01e5f56ecec7b2d227b23f7fb52fbb0d3d843c"
  end

  depends_on "docbook" => :build
  depends_on "docbook-xsl" => :build
  depends_on "gobject-introspection" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "gdk-pixbuf"
  depends_on "glib"
  depends_on "json-glib"
  depends_on "libarchive"

  uses_from_macos "gperf" => :build
  uses_from_macos "curl"

  on_macos do
    depends_on "gettext"
  end

  on_linux do
    depends_on "util-linux"
  end

  # see https://github.com/hughsie/appstream-glib/issues/258
  patch :DATA

  def install
    # Find our docbook catalog
    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog"

    system "meson", "setup", "build", "-Dbuilder=false", "-Drpm=false", "-Ddep11=false", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <appstream-glib.h>

      int main(int argc, char *argv[]) {
        AsScreenshot *screen_shot = as_screenshot_new();
        g_assert_nonnull(screen_shot);
        return 0;
      }
    C

    ENV.prepend_path "PKG_CONFIG_PATH", Formula["libarchive"].opt_lib/"pkgconfig"
    flags = shell_output("pkgconf --cflags --libs appstream-glib").chomp.split
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
    system bin/"appstream-util", "--help"
  end
end

__END__
diff --git a/libappstream-glib/meson.build b/libappstream-glib/meson.build
index 5f726b0..7d29ac8 100644
--- a/libappstream-glib/meson.build
+++ b/libappstream-glib/meson.build
@@ -136,7 +136,6 @@ asglib = shared_library(
   dependencies : deps,
   c_args : cargs,
   include_directories : include_directories('..'),
-  link_args : vflag,
   link_depends : mapfile,
   install : true,
 )
