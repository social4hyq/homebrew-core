class Bgpq3 < Formula
  desc "BGP filtering automation for Cisco, Juniper, BIRD and OpenBGPD routers"
  homepage "http://snar.spb.ru/prog/bgpq3/"
  url "https://github.com/snar/bgpq3/archive/refs/tags/v0.1.38.tar.gz"
  sha256 "c4a424825e6c9c9ec48c2583dcbbfc3016d15cc0be1dc55d07827e1b9b79888c"
  license "BSD-2-Clause"
  head "https://github.com/snar/bgpq3.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e5a4ebbe6e291bf8f8c9cb841f6f0120601b4dc4a300493c6526afaf996940d5"
  end

  # Makefile: upstream has been informed of the patch through email (multiple
  # times) but no plans yet to incorporate it https://github.com/snar/bgpq3/pull/2
  # there was discussion about this patch for 0.1.18 and 0.1.19 as well
  patch :DATA

  def install
    system "./configure", "--prefix=#{prefix}", "--mandir=#{man}"
    system "make", "install"
  end

  test do
    system bin/"bgpq3", "AS-ANY"
  end
end

__END__
--- a/Makefile.in
+++ b/Makefile.in
@@ -32,8 +32,8 @@
 install: bgpq3
 	if test ! -d @bindir@ ; then mkdir -p @bindir@ ; fi
 	${INSTALL} -c -s -m 755 bgpq3 @bindir@
-	if test ! -d @prefix@/man/man8 ; then mkdir -p @prefix@/man/man8 ; fi
-	${INSTALL} -m 644 bgpq3.8 @prefix@/man/man8
+	if test ! -d @mandir@/man8 ; then mkdir -p @mandir@/man8 ; fi
+	${INSTALL} -m 644 bgpq3.8 @mandir@/man8

 depend:
 	makedepend -- $(CFLAGS) -- $(SRCS)
