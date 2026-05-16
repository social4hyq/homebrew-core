class Libspiro < Formula
  desc "Library to simplify the drawing of curves"
  homepage "https://github.com/fontforge/libspiro"
  url "https://github.com/fontforge/libspiro/releases/download/20240903/libspiro-dist-20240903.tar.gz"
  sha256 "1412a21b943c6e1db834ee2d74145aad20b3f62b12152d475613b8241d9cde10"
  license "GPL-3.0-or-later"
  version_scheme 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c9f11f24879b9f183c99d90e73c7397131ef58920fa5d7d5975b33082bb36828"
  end

  head do
    url "https://github.com/fontforge/libspiro.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  def install
    if build.head?
      system "autoreconf", "--force", "--install", "--verbose"
      system "automake"
    end

    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <spiroentrypoints.h>
      #include <bezctx.h>

      void moveto(bezctx *bc, double x, double y, int open) {}
      void lineto(bezctx *bc, double x, double y) {}
      void quadto(bezctx *bc, double x1, double y1, double x2, double y2) {}
      void curveto(bezctx *bc, double x1, double y1, double x2, double y2, double x3, double t3) {}
      void markknot(bezctx *bc, int knot) {}

      int main() {
        int done;
        bezctx bc = {moveto, lineto, quadto, curveto, markknot};
        spiro_cp path[] = {
          {-100, 0, SPIRO_G4}, {0, 100, SPIRO_G4},
          {100, 0, SPIRO_G4}, {0, -100, SPIRO_G4}
        };

        SpiroCPsToBezier1(path, sizeof(path)/sizeof(spiro_cp), 1, &bc, &done);
        return done == 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lspiro", "-o", "test"
    system "./test"
  end
end
