class Bsdiff < Formula
  desc "Generate and apply patches to binary files"
  homepage "https://www.daemonology.net/bsdiff/"
  # Returns 403 (forbidden) for the canonical download URL:
  # "https://www.daemonology.net/bsdiff/bsdiff-4.3.tar.gz"
  url "https://deb.debian.org/debian/pool/main/b/bsdiff/bsdiff_4.3.orig.tar.gz"
  sha256 "18821588b2dc5bf159aa37d3bcb7b885d85ffd1e19f23a0c57a58723fea85f48"
  license "BSD-2-Clause"

  livecheck do
    url :homepage
    regex(/href=.*?bsdiff[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6ce1c23193ed273a76c3e7f0c13d5825437515c3f212060611dcda82d130d6be"
  end

  depends_on "bmake" => :build

  uses_from_macos "bzip2"

  patch :DATA

  def install
    ENV.append "LDLIBS", "-lbz2" unless OS.mac?
    system "bmake"
    bin.install "bsdiff"
    man1.install "bsdiff.1"
  end

  test do
    (testpath/"bin1").write "\x01\x02\x03\x04"
    (testpath/"bin2").write "\x01\x02\x03\x05"

    system bin/"bsdiff", "bin1", "bin2", "bindiff"
  end
end

__END__
diff --git a/bspatch.c b/bspatch.c
index 643c60b..543379c 100644
--- a/bspatch.c
+++ b/bspatch.c
@@ -28,6 +28,7 @@
 __FBSDID("$FreeBSD: src/usr.bin/bsdiff/bspatch/bspatch.c,v 1.1 2005/08/06 01:59:06 cperciva Exp $");
 #endif

+#include <sys/types.h>
 #include <bzlib.h>
 #include <stdlib.h>
 #include <stdio.h>
