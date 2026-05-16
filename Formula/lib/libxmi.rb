class Libxmi < Formula
  desc "C/C++ function library for rasterizing 2D vector graphics"
  homepage "https://www.gnu.org/software/libxmi/"
  url "https://ftpmirror.gnu.org/gnu/libxmi/libxmi-1.2.tar.gz"
  mirror "https://ftp.gnu.org/gnu/libxmi/libxmi-1.2.tar.gz"
  sha256 "9d56af6d6c41468ca658eb6c4ba33ff7967a388b606dc503cd68d024e08ca40d"
  license "GPL-2.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3430842cc41ac3cc0d05ccc12f802249e76b2e204ce07d76ac824fd842e6e734"
  end

  on_system :linux, macos: :ventura_or_newer do
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  def install
    system "autoreconf", "--force", "--install", "--verbose" if OS.linux? || (OS.mac? && MacOS.version >= :ventura)
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}", "--infodir=#{info}"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <stdlib.h>
      #include <xmi.h>
      int main () {
        miPoint points[4] = {{.x = 25, .y = 0}, {.x = 0, .y = 0}, {.x = 0, .y = 25}, {.x = 35, .y = 22}};
        miArc arc = {.x = 20, .y = 15, .width = 30, .height = 16, .angle1 = 0 * 64, .angle2 = 270 * 64};
        miPixel pixels[4] = {1, 2, 3, 4};
        unsigned int dashes[2] = {4, 2};
        miGC *pGC;
        miPaintedSet *paintedSet;
        miCanvas *canvas;
        miPoint offset = {.x = 0, .y = 0};
        int i, j;
        pGC = miNewGC (4, pixels);
        miSetGCAttrib (pGC, MI_GC_LINE_STYLE, MI_LINE_ON_OFF_DASH);
        miSetGCDashes (pGC, 2, dashes, 0);
        miSetGCAttrib (pGC, MI_GC_LINE_WIDTH, 0);
        paintedSet = miNewPaintedSet ();
        miDrawLines (paintedSet, pGC, MI_COORD_MODE_ORIGIN, 4, points);
        miDrawArcs (paintedSet, pGC, 1, &arc);
        canvas = miNewCanvas (51, 32, 0);
        miCopyPaintedSetToCanvas (paintedSet, canvas, offset);
        for (j = 0; j < canvas->drawable->height; j++) {
          for (i = 0; i < canvas->drawable->width; i++) {
            printf ("%d", canvas->drawable->pixmap[j][i]);
          }
          printf ("\\n");
        }
        miDeleteCanvas (canvas);
        miDeleteGC (pGC);
        miClearPaintedSet (paintedSet);
        miDeletePaintedSet (paintedSet);
        return 0;
      }
    C

    expected = <<~EOS
      330022220044440033330022220000000000000000000000000\n300000000000000000000000000000000000000000000000000
      300000000000000000000000000000000000000000000000000\n000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000\n400000000000000000000000000000000000000000000000000
      400000000000000000000000000000000000000000000000000\n400000000000000000000000000000000000000000000000000
      400000000000000000000000000000000000000000000000000\n000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000\n200000000000000000000000000000000000000000000000000
      200000000000000000000000000000000000000000000000000\n200000000000000000000000000000000000000000000000000
      200000000000000000000000000000000000000000000000000\n000000000000000000000000000000022220044440000000000
      000000000000000000000000000330000000000000030000000\n300000000000000000000000033000000000000000003300000
      300000000000000000000000000000000000000000000030000\n300000000000000000000040000000000000000000000000000
      300000000000000000000400000000000000000000000000020\n000000000000000000004000000000000000000000000000002
      000000000000000000004000000000330044000000000000002\n400000000000000000440022220033000000000000000000002
      400000220033330044000000000000000000000000000000000\n440022000000000000002000000000000000000000000000000
      000000000000000000000200000000000000000000000000000\n000000000000000000000020000000000000000000000000000
      000000000000000000000002000000000000000000000000000\n000000000000000000000000003000000000000000000000000
      000000000000000000000000000333000000000000000000000\n000000000000000000000000000000004444000000000000000
    EOS

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lxmi", "-o", "test"
    assert_equal expected, shell_output("./test")
  end
end
