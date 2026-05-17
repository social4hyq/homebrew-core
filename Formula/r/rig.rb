class Rig < Formula
  desc "Provides fake name and address data"
  homepage "https://rig.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/rig/rig/1.11/rig-1.11.tar.gz"
  sha256 "00bfc970d5c038c1e68bc356c6aa6f9a12995914b7d4fda69897622cb5b77ab8"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "76deca5b317838015494d37faa88d558835c3909f9e2752ac1331f12f919d8f3"
  end

  conflicts_with "r-rig", because: "both install `rig` binary"

  # Fix build failure because of missing #include <cstring> on Linux.
  # Patch submitted to author by email.
  patch :DATA

  def install
    system "make", "PREFIX=#{prefix}"
    bin.install "rig"
    pkgshare.install Dir["data/*"]
  end

  test do
    system bin/"rig"
  end
end

__END__
diff --git a/rig.cc b/rig.cc
index 1f9a2e4..3a23ea8 100644
--- a/rig.cc
+++ b/rig.cc
@@ -21,6 +21,7 @@
 #include <fstream>
 #include <vector>
 #include <string>
+#include <cstring>
 #include <stdlib.h>
 #include <unistd.h>
 #include <time.h>
