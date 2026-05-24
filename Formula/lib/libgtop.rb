class Libgtop < Formula
  desc "Library for portably obtaining information about processes"
  homepage "https://gitlab.gnome.org/GNOME/libgtop"
  url "https://download.gnome.org/sources/libgtop/2.40/libgtop-2.40.0.tar.xz"
  sha256 "78f3274c0c79c434c03655c1b35edf7b95ec0421430897fb1345a98a265ed2d4"
  license "GPL-2.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c0581cd4f576e54534571a0195089166cb78c50d1f11ccf57d244552be319333"
  end

  depends_on "gobject-introspection" => :build
  depends_on "intltool" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "glib"
  depends_on "libxau"

  on_macos do
    depends_on "gettext"
  end

  def install
    # workaround for newer clang
    # upstream bug report, https://gitlab.gnome.org/GNOME/libgtop/-/issues/73
    ENV.append_to_cflags "-Wno-int-conversion" if DevelopmentTools.clang_build_version >= 1403

    system "./configure", "--without-x", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <glibtop/sysinfo.h>

      int main(int argc, char *argv[]) {
        const glibtop_sysinfo *info = glibtop_get_sysinfo();
        return 0;
      }
    C

    flags = shell_output("pkgconf --cflags --libs libgtop-2.0").chomp.split
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
