class Libp11 < Formula
  desc "PKCS#11 wrapper library in C"
  homepage "https://github.com/OpenSC/libp11/wiki"
  url "https://github.com/OpenSC/libp11/releases/download/libp11-0.4.19/libp11-0.4.19.tar.gz"
  sha256 "a344ca201ffa71822881e45e86457ab9a0115d07d03da0d69c7e5a7268255a35"
  license "LGPL-2.1-or-later"

  livecheck do
    url :stable
    regex(/^libp11[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a2db39555147d5bac32bdc2b7146af98d694f88b0e280b6d51e43d07619ed825"
  end

  head do
    url "https://github.com/OpenSC/libp11.git", branch: "master"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  depends_on "pkgconf" => :build
  depends_on "libtool"
  depends_on "openssl@3"

  # Install missing `p11_ver.h` header
  # https://github.com/OpenSC/libp11/pull/662
  patch :DATA

  def install
    openssl = deps.find { |d| d.name.match?(/^openssl/) }
                  .to_formula
    enginesdir = Utils.safe_popen_read("pkgconf", "--variable=enginesdir", "libcrypto").chomp
    enginesdir.sub!(openssl.prefix.realpath, prefix)

    modulesdir = Utils.safe_popen_read("pkgconf", "--variable=modulesdir", "libcrypto").chomp
    modulesdir.sub!(openssl.prefix.realpath, prefix)

    system "./bootstrap" if build.head?
    system "./configure", "--disable-silent-rules",
                          "--with-enginesdir=#{enginesdir}",
                          "--with-modulesdir=#{modulesdir}",
                          *std_configure_args
    system "make", "install"
    pkgshare.install "examples/auth.c"
  end

  test do
    system ENV.cc, pkgshare/"auth.c", "-I#{Formula["openssl@3"].include}",
                   "-L#{lib}", "-L#{Formula["openssl@3"].lib}",
                   "-lp11", "-lcrypto", "-o", "test"
  end
end

__END__
diff --git a/src/Makefile.am b/src/Makefile.am
index 92d3fdb..549ac67 100644
--- a/src/Makefile.am
+++ b/src/Makefile.am
@@ -9,7 +9,7 @@ EXTRA_DIST = Makefile.mak libp11.rc.in pkcs11.rc.in
 
 # Headers
 noinst_HEADERS= libp11-int.h pkcs11.h p11_pthread.h provider_helpers.h util.h
-include_HEADERS= libp11.h p11_err.h
+include_HEADERS= libp11.h p11_err.h p11_ver.h
 
 lib_LTLIBRARIES = libp11.la
 enginesexec_LTLIBRARIES =
diff --git a/src/Makefile.in b/src/Makefile.in
index 797be54..4a1638d 100644
--- a/src/Makefile.in
+++ b/src/Makefile.in
@@ -492,7 +492,7 @@ EXTRA_DIST = Makefile.mak libp11.rc.in pkcs11.rc.in $(am__append_3)
 
 # Headers
 noinst_HEADERS = libp11-int.h pkcs11.h p11_pthread.h provider_helpers.h util.h
-include_HEADERS = libp11.h p11_err.h
+include_HEADERS = libp11.h p11_err.h p11_ver.h
 lib_LTLIBRARIES = libp11.la $(am__append_2)
 enginesexec_LTLIBRARIES = $(am__append_1)
 pkgconfig_DATA = libp11.pc
