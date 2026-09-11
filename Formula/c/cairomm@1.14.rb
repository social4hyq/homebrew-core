class CairommAT114 < Formula
  desc "Vector graphics library with cross-device output support"
  homepage "https://cairographics.org/cairomm/"
  url "https://cairographics.org/releases/cairomm-1.14.6.tar.xz"
  sha256 "7e0d5c7f29175d573a03ab5c45aef63f48dd91a5caf335a404cd763e4b7cea4a"
  license "LGPL-2.0-or-later"
  revision 1

  livecheck do
    url "https://cairographics.org/releases/?C=M&O=D"
    regex(/href=.*?cairomm[._-]v?(1\.14(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f7edb3fa658c7d400989560349ed220b21667e872809dd5f2afe7f88c9f76e65"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "cairo"
  depends_on "libpng"
  depends_on "libsigc++@2"

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <cairomm/cairomm.h>

      int main(int argc, char *argv[])
      {
         Cairo::RefPtr<Cairo::ImageSurface> surface = Cairo::ImageSurface::create(Cairo::FORMAT_ARGB32, 600, 400);
         Cairo::RefPtr<Cairo::Context> cr = Cairo::Context::create(surface);
         return 0;
      }
    CPP

    pkg_config_cflags = shell_output("pkg-config --cflags --libs cairo cairomm-1.0").chomp.split
    system ENV.cxx, "-std=c++11", "test.cpp", *pkg_config_cflags, "-o", "test"
    system "./test"
  end
end
