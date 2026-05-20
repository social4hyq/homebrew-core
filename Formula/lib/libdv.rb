class Libdv < Formula
  desc "Codec for DV video encoding format"
  homepage "https://libdv.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/libdv/libdv/1.0.0/libdv-1.0.0.tar.gz"
  sha256 "a305734033a9c25541a59e8dd1c254409953269ea7c710c39e540bd8853389ba"
  license "LGPL-2.1-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8137d9a3a6cdbef4cf8c0a31a0a36fbcc10d5abaa6f8e2be9a72aa49ef70b1a7"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "popt"

  # remove SDL1 dependency by force
  patch :DATA

  def install
    # This fixes an undefined symbol error on compile.
    # See the port file for libdv:
    #   https://trac.macports.org/browser/trunk/dports/multimedia/libdv/Portfile
    # This flag is the preferred method over what macports uses.
    # See the apple docs: https://cl.ly/2HeF bottom of the "Finding Imported Symbols" section
    ENV.append "LDFLAGS", "-undefined dynamic_lookup" if OS.mac?

    system "autoreconf", "--force", "--install", "--verbose"

    # Fix compile with newer Clang
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    system "./configure", "--disable-asm",
                          "--disable-gtktest",
                          "--disable-gtk",
                          "--disable-sdltest",
                          *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"dubdv", "--version"
    system bin/"dvconnect", "--version"
  end
end

__END__
diff --git a/configure.ac b/configure.ac
index 2b95735..1ba9370 100644
--- a/configure.ac
+++ b/configure.ac
@@ -173,13 +173,6 @@ dnl used in Makefile.am
 AC_SUBST(GTK_CFLAGS)
 AC_SUBST(GTK_LIBS)
 
-if $use_sdl; then
-	AM_PATH_SDL(1.1.6,
-	[
-		AC_DEFINE(HAVE_SDL) 
- 	])
-fi
-
 if [ $use_gtk && $use_xv ]; then
 	AC_CHECK_LIB(Xv, XvQueryAdaptors,
 		[AC_DEFINE(HAVE_LIBXV)
