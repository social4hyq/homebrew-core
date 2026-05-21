class Ntbtls < Formula
  desc "Not Too Bad TLS Library"
  homepage "https://gnupg.org/"
  url "https://gnupg.org/ftp/gcrypt/ntbtls/ntbtls-0.3.2.tar.bz2"
  sha256 "bdfcb99024acec9c6c4b998ad63bb3921df4cfee4a772ad6c0ca324dbbf2b07c"
  license "GPL-3.0-or-later"

  livecheck do
    url "https://gnupg.org/download/"
    regex(/href=.*?ntbtls[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "46b4160ddc866c3331244aba43d2905595cf4ab79925a6de565d57ffe7feb4c5"
  end

  depends_on "libgcrypt"
  depends_on "libgpg-error"
  depends_on "libksba"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--with-libgpg-error-prefix=#{Formula["libgpg-error"].opt_prefix}",
                          "--with-libgcrypt-prefix=#{Formula["libgcrypt"].opt_prefix}",
                          "--with-libksba-prefix=#{Formula["libksba"].opt_prefix}"
    system "make", "check" # This is a TLS library, so let's run `make check`.
    system "make", "install"
    inreplace bin/"ntbtls-config", prefix, opt_prefix
  end

  test do
    (testpath/"ntbtls_test.c").write <<~C
      #include "ntbtls.h"
      #include <stdio.h>
      int main() {
        printf("%s", ntbtls_check_version(NULL));
        return 0;
      }
    C

    ENV.append_to_cflags shell_output("#{bin}/ntbtls-config --cflags").strip
    ENV.append "LDLIBS", shell_output("#{bin}/ntbtls-config --libs").strip

    system "make", "ntbtls_test"
    assert_equal version.to_s, shell_output("./ntbtls_test")
  end
end
