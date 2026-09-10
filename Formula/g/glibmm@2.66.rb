class GlibmmAT266 < Formula
  desc "C++ interface to glib"
  homepage "https://gtkmm.gnome.org/"
  url "https://download.gnome.org/sources/glibmm/2.66/glibmm-2.66.10.tar.xz"
  sha256 "2b61780203aed98e701d3ea57c8f353e7c8ada9706a79be782f6c5153dd035c0"
  license "LGPL-2.1-or-later"
  revision 1

  livecheck do
    url "https://download.gnome.org/sources/glibmm/2.66/"
    regex(/href=.*?glibmm[._-]v?(2\.66(?:\.\d+)+)\.t/i)
    strategy :page_match
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6d5e517a93a88092bb631cae7129a3d80e01c7601c807225e3878ffb34b94285"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "glib"
  depends_on "libsigc++@2"

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <glibmm.h>

      int main(int argc, char *argv[])
      {
         Glib::ustring my_string("testing");
         return 0;
      }
    CPP

    flags = shell_output("pkgconf --cflags --libs glibmm-2.4").chomp.split
    system ENV.cxx, "-std=c++11", "test.cpp", "-o", "test", *flags
    system "./test"
  end
end
