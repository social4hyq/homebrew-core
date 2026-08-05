class Libxfont2 < Formula
  desc "X11 font rasterisation library"
  homepage "https://www.x.org/"
  url "https://xorg.freedesktop.org/archive/individual/lib/libXfont2-2.0.9.tar.gz"
  sha256 "8564b4df365bc5a6cb0c15900dc688f6e8f47b00a8571c6708c916dfb85066ba"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1b77daf799aa36396afca8ca0d8dd75d48903a184a0a3bfce24bbfc80108740f"
  end

  depends_on "pkgconf" => :build
  depends_on "util-macros" => :build
  depends_on "xorgproto" => [:build, :test]
  depends_on "xtrans" => :build

  depends_on "freetype"
  depends_on "libfontenc"

  uses_from_macos "bzip2"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    configure_args = %w[
      --with-bzip2
      --enable-devel-docs=no
      --enable-snfformat
      --enable-unix-transport
      --enable-tcp-transport
      --enable-ipv6
    ]

    system "./configure", *configure_args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stddef.h>
      #include <X11/fonts/fontstruct.h>
      #include <X11/fonts/libxfont2.h>

      int main(int argc, char* argv[]) {
        xfont2_init(NULL);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-o", "test",
      "-I#{include}", "-I#{Formula["xorgproto"].include}",
      "-L#{lib}", "-lXfont2"
    system "./test"
  end
end
