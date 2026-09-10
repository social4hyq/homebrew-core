class Pixman < Formula
  desc "Low-level library for pixel manipulation"
  homepage "https://cairographics.org/"
  url "https://cairographics.org/releases/pixman-0.46.4.tar.gz"
  sha256 "d09c44ebc3bd5bee7021c79f922fe8fb2fb57f7320f55e97ff9914d2346a591c"
  license "MIT"
  revision 1
  compatibility_version 1

  livecheck do
    url "https://cairographics.org/releases/?C=M&O=D"
    regex(/href=.*?pixman[._-]v?(\d+\.\d*[02468](?:\.\d+)*)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "89a4ee061de03a8dd91e9cd32499236c039f32edbec69b11a7bcf59f10c53890"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :test

  def install
    system "meson", "setup", "build", "--default-library=both", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <pixman.h>

      int main(int argc, char *argv[])
      {
        pixman_color_t white = { 0xffff, 0xffff, 0xffff, 0xffff };
        pixman_image_t *image = pixman_image_create_solid_fill(&white);
        pixman_image_unref(image);
        return 0;
      }
    C

    pkgconf_flags = shell_output("pkgconf --cflags --libs pixman-1").chomp.split
    system ENV.cc, "test.c", "-o", "test", *pkgconf_flags
    system "./test"
  end
end
