class PangommAT246 < Formula
  desc "C++ interface to Pango"
  homepage "https://www.gtk.org/docs/architecture/pango"
  url "https://download.gnome.org/sources/pangomm/2.46/pangomm-2.46.5.tar.xz"
  sha256 "38ca0b050b065de4e3da0c182df657437757063bbf0c4b6c9567ddba019b1d68"
  license "LGPL-2.1-only"
  revision 1

  livecheck do
    url :stable
    regex(/pangomm-(2\.46(?:\.\d+)*)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c912d1b03b33f632b64df6c37806e24901111606e4247876db3b4614b99d9839"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "cairomm@1.14"
  depends_on "glib"
  depends_on "glibmm@2.66"
  depends_on "libsigc++@2"
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

    pkgconf_flags = shell_output("pkgconf --cflags --libs pangomm-1.4").chomp.split
    system ENV.cxx, "-std=c++11", "test.cpp", *pkgconf_flags, "-o", "test"
    system "./test"
  end
end
