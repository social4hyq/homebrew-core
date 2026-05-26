class Unac < Formula
  desc "C library and command that removes accents from a string"
  homepage "https://savannah.nongnu.org/projects/unac"
  url "https://deb.debian.org/debian/pool/main/u/unac/unac_1.8.0.orig.tar.gz"
  sha256 "29d316e5b74615d49237556929e95e0d68c4b77a0a0cfc346dc61cf0684b90bf"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://deb.debian.org/debian/pool/main/u/unac/"
    regex(/href=.*?unac[._-]v?(\d+(?:\.\d+)+)\.orig\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e8a9be3dfca709bf60eb7a60f00bc42a16d2fddd274bdce7265bdc59755b126c"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "gettext" => :build
  depends_on "libtool" => :build

  on_macos do
    # configure.ac doesn't properly detect Mac OS's iconv library. This patch fixes that.
    patch :DATA
  end

  # Patches from https://udd.debian.org/patches.cgi?src=unac&version=1.8.0-8
  patch do
    url "https://sources.debian.org/data/main/u/unac/1.8.0-8/debian/patches/gcc-4-fix-bug-556379.patch"
    sha256 "f91d2c376826ff05eba7a13ee37b8152851f2c24ced29ee88afdf9b42b6a2fc8"
  end

  patch do
    url "https://sources.debian.org/data/main/u/unac/1.8.0-8/debian/patches/update-autotools.diff"
    sha256 "8310103e199edf477e3f3fd961a2ecb09bf361ba1602871b8a223b1ee65cc11a"
  end

  def install
    ENV.append_path "ACLOCAL_PATH", Formula["gettext"].pkgshare/"m4"

    touch "config.rpath"
    inreplace "autogen.sh", "libtool", "glibtool"
    system "./autogen.sh"
    system "./configure", *std_configure_args

    # Separate steps to prevent race condition in folder creation
    system "make"
    ENV.deparallelize
    system "make", "install"
  end

  test do
    assert_equal "foo", shell_output("#{bin}/unaccent utf-8 fóó").strip
  end
end

__END__
diff --git a/configure.ac b/configure.ac
index 4a4eab6..9f25d50 100644
--- a/configure.ac
+++ b/configure.ac
@@ -49,6 +49,7 @@ AM_MAINTAINER_MODE

 AM_ICONV

+LIBS="$LIBS -liconv"
 AC_CHECK_FUNCS(iconv_open,,AC_MSG_ERROR([
 iconv_open not found try to install replacement from
 http://www.gnu.org/software/libiconv/
