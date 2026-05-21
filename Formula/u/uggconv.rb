class Uggconv < Formula
  desc "Universal Game Genie code converter"
  homepage "https://web.archive.org/web/20230505074213/https://wyrmcorp.com/software/uggconv/index.shtml"
  url "https://web.archive.org/web/20230505074320/https://wyrmcorp.com/software/uggconv/uggconv-1.0.tar.gz"
  sha256 "9a215429bc692b38d88d11f38ec40f43713576193558cd8ca6c239541b1dd7b8"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c158fde5b0e46e46849b9c06604a1917aafef8d6900e3496480bb924efee6140"
  end

  # upstream is gone
  deprecate! date: "2024-09-11", because: :repo_removed
  disable! date: "2025-09-11", because: :repo_removed

  # Add missing `#include`.
  patch :DATA

  def install
    system "make"
    bin.install "uggconv"
    man1.install "uggconv.1"
  end

  test do
    assert_equal "7E00CE:03    = D7DA-FE86\n",
      shell_output("#{bin}/uggconv -s 7E00CE:03")
  end
end

__END__
--- a/uggconv.c
+++ b/uggconv.c
@@ -47,6 +47,7 @@
  */
 
 #include <stdio.h>
+#include <stdlib.h>
 #include <string.h>
 #include <ctype.h>
 
