class MuslCompat < Formula
  desc "Compatibility shim for musl symbols missing on OpenHarmony"
  homepage "https://atomgit.com/Harmonybrew/musl-compat"
  url "https://raw.atomgit.com/Harmonybrew/musl-compat/archive/refs/heads/v1.0.0.tar.gz"
  sha256 "72104ecc504e86c12291cd5457ba9d9f660fce6c034ed44b1cc32b7a73d63020"
  license "MIT"

  def install
    system "make", "static", "shared",
           "CC=#{ENV.cc}",
           "CFLAGS=-O2 -fPIC",
           "PREFIX=#{prefix}"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "musl_compat.h"
      #include <stdio.h>
      #include <string.h>
      static int cmp_int(const void *a, const void *b, void *arg) {
          (void)arg;
          return *(const int*)a - *(const int*)b;
      }
      int main() {
        int arr[] = {3, 1, 4, 1, 5, 9, 2, 6};
        int expected[] = {1, 1, 2, 3, 4, 5, 6, 9};
        qsort_r(arr, 8, sizeof(int), cmp_int, NULL);
        if (memcmp(arr, expected, sizeof(arr)) == 0) {
          printf("musl-compat OK\\n");
          return 0;
        }
        printf("FAIL: sort mismatch\\n");
        return 1;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lmusl_compat",
           "-o", "test"
    system "./test"
  end
end
