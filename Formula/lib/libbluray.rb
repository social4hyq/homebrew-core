class Libbluray < Formula
  desc "Blu-Ray disc playback library for media players like VLC"
  homepage "https://www.videolan.org/developers/libbluray.html"
  url "https://download.videolan.org/videolan/libbluray/1.5.0/libbluray-1.5.0.tar.xz"
  sha256 "f676408e91a5d321abf8b8d4dfdae36205c297dab5c54c3ec519639025f474a2"
  license "LGPL-2.1-or-later"
  compatibility_version 1
  head "https://code.videolan.org/videolan/libbluray.git", branch: "master"

  livecheck do
    url "https://download.videolan.org/pub/videolan/libbluray/"
    regex(%r{href=["']?v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "de2b345e17fa76d2629ed1380cce71b02897578f04f7ae90545e9e77a89256ff"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "libudfread"

  uses_from_macos "libxml2"

  def install
    args = %w[
      -Dbdj_jar=disabled
      -Dfontconfig=enabled
      -Dfreetype=enabled
      -Dlibxml2=enabled
    ]
    system "meson", "setup", "build", *args, *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <libbluray/bluray.h>
      int main(void) {
        BLURAY *bluray = bd_init();
        bd_close(bluray);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lbluray", "-o", "test"
    system "./test"
  end
end
