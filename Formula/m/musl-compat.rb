class MuslCompat < Formula
  desc "Compatibility shim for musl symbols missing on OpenHarmony"
  homepage "https://atomgit.com/Harmonybrew/musl-compat"
  url "https://raw.atomgit.com/Harmonybrew/musl-compat/archive/refs/heads/v1.0.1.tar.gz"
  sha256 "b3e4d8da001019b09a2d7d15198000b0d6c00307f3857eb956f057cc6ec144bb"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "92a6c6a98c21677fb42ba13c875b3d0d4a92d89f3540279062697576d6213c60"
  end

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
