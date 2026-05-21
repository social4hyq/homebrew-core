class Nload < Formula
  desc "Realtime console network usage monitor"
  homepage "https://www.roland-riegel.de/nload/"
  url "https://www.roland-riegel.de/nload/nload-0.7.4.tar.gz"
  sha256 "c1c051e7155e26243d569be5d99c744d8620e65fa8a7e05efcf84d01d9d469e5"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?nload[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "84ca90687cb58630e1172d4989a17ac2db74e1349a693309facd987cd3f9eee1"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  uses_from_macos "ncurses"

  # crash on F2 and garbage in adapter name, see https://sourceforge.net/p/nload/bugs/8/ reported on 2014-04-03
  patch :p0 do
    url "https://sourceforge.net/p/nload/bugs/_discuss/thread/c9b68d8e/4a65/attachment/devreader-bsd.cpp.patch"
    sha256 "19055158b72722f7dabff9890931094cac591bcc6de3e90a7f4744d28746ebc7"
  end

  # Patching configure.in file to make configure compile on Mac OS.
  # Patch taken from MacPorts.
  patch :DATA

  def install
    system "./run_autotools"
    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    # Unset LDFLAGS, "-s" causes the linker to crash
    system "make", "install", "LDFLAGS="
  end

  test do
    system bin/"nload", "--help"
  end
end


__END__
diff --git a/configure.in b/configure.in
index 87ecc88..4df8dc3 100644
--- a/configure.in
+++ b/configure.in
@@ -38,7 +38,7 @@ case $host_os in
 
         AC_CHECK_FUNCS([memset])
         ;;
-    *bsd*)
+    *darwin*)
         AC_DEFINE(HAVE_BSD, 1, [Define to 1 if your build target is BSD.])
         AM_CONDITIONAL(HAVE_BSD, true)
