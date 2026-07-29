class Libaacs < Formula
  desc "Implements the Advanced Access Content System specification"
  homepage "https://www.videolan.org/developers/libaacs.html"
  url "https://get.videolan.org/libaacs/0.12.0/libaacs-0.12.0.tar.bz2"
  mirror "https://download.videolan.org/pub/videolan/libaacs/0.12.0/libaacs-0.12.0.tar.bz2"
  sha256 "1996673a9fc45ee4a364c66ffa84756629bf3923e52346c7358b71becb8e4419"
  license "LGPL-2.1-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?libaacs[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dd0094b0f334d48de0a2e6e1a15514c34b04562bea4e4b3d159e8acb969f2a9c"
  end

  head do
    url "https://code.videolan.org/videolan/libaacs.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "bison" => :build
  depends_on "libgcrypt"
  depends_on "libgpg-error"

  uses_from_macos "flex" => :build

  # Fix missing include.
  patch :DATA

  def install
    system "./bootstrap" if build.head?
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "libaacs/aacs.h"
      #include <stdio.h>

      int main() {
        int major_v = 0, minor_v = 0, micro_v = 0;

        aacs_get_version(&major_v, &minor_v, &micro_v);

        printf("%d.%d.%d", major_v, minor_v, micro_v);
        return(0);
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-laacs",
                   "-o", "test"
    system "./test"
  end
end
__END__
diff --git a/src/devtools/read_file.h b/src/devtools/read_file.h
index 953b2ef..d218417 100644
--- a/src/devtools/read_file.h
+++ b/src/devtools/read_file.h
@@ -20,6 +20,7 @@
 #include <stdio.h>
 #include <stdlib.h>
 #include <errno.h>
+#include <sys/types.h>

 static size_t _read_file(const char *name, off_t min_size, off_t max_size, uint8_t **pdata)
 {
