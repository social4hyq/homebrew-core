class Mle < Formula
  desc "Flexible terminal-based text editor"
  homepage "https://github.com/adsr/mle"
  url "https://github.com/adsr/mle/archive/refs/tags/v1.8.1.tar.gz"
  sha256 "7ee33a695f801024254fc717b64aff6a7a4c274874fc4b83e1a23ccf1a74b9ca"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "56b906682b2324810186346d4e95aac2264cf4af3694077c994eddb8befcb439"
  end

  depends_on "uthash" => :build
  depends_on "lua"
  depends_on "pcre2"

  # Backport support for Lua 5.5
  # https://github.com/adsr/mle/commit/3325a1b73d546201c419d9150ff3a10d13ebcb6d
  patch :DATA

  def install
    system "make", "install", "prefix=#{prefix}"
  end

  test do
    output = pipe_output("#{bin}/mle -M 'test C-e space w o r l d enter' -p test", "hello")
    assert_equal "hello world\n", output
  end
end

__END__
diff --git a/Makefile b/Makefile
index 9d77497..7436b03 100644
--- a/Makefile
+++ b/Makefile
@@ -2,8 +2,8 @@ prefix?=/usr/local
 
 mle_cflags:=-std=c99 -Wall -Wextra -pedantic -Wno-pointer-arith -Wno-unused-result -Wno-unused-parameter -g -O0 -D_GNU_SOURCE -DPCRE2_CODE_UNIT_WIDTH=8 -I. $(CFLAGS) $(CPPFLAGS)
 mle_ldflags:=$(LDFLAGS)
-mle_dynamic_libs:=-lpcre2-8 -llua5.4
-mle_static_libs:=vendor/pcre2/libpcre2-8.a vendor/lua/liblua5.4.a
+mle_dynamic_libs:=-lpcre2-8 -llua5.5
+mle_static_libs:=vendor/pcre2/libpcre2-8.a vendor/lua/liblua5.5.a
 mle_ldlibs:=-lm $(LDLIBS)
 mle_objects:=$(patsubst %.c,%.o,$(filter-out %.inc.c,$(wildcard *.c)))
 mle_objects_no_main:=$(filter-out main.o,$(mle_objects))
diff --git a/mle.h b/mle.h
index f77f98f..af7a078 100644
--- a/mle.h
+++ b/mle.h
@@ -4,9 +4,9 @@
 #include <stdint.h>
 #include <limits.h>
 #include <uthash.h>
-#include <lua5.4/lua.h>
-#include <lua5.4/lualib.h>
-#include <lua5.4/lauxlib.h>
+#include <lua5.5/lua.h>
+#include <lua5.5/lualib.h>
+#include <lua5.5/lauxlib.h>
 #include "termbox2.h"
 #include "mlbuf.h"
