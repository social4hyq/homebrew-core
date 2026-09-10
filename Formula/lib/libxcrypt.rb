class Libxcrypt < Formula
  desc "Extended crypt library for descrypt, md5crypt, bcrypt, and others"
  homepage "https://github.com/besser82/libxcrypt"
  url "https://github.com/besser82/libxcrypt/releases/download/v4.5.2/libxcrypt-4.5.2.tar.xz"
  sha256 "71513a31c01a428bccd5367a32fd95f115d6dac50fb5b60c779d5c7942aec071"
  license "LGPL-2.1-or-later"
  revision 1
  compatibility_version 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c173cd0db1a96f61905f6f2e5322db67d66b3017c928b31bcc3890d61a4c3fc0"
  end

  keg_only :provided_by_macos

  depends_on "pkgconf" => :build

  link_overwrite "include/crypt.h"
  link_overwrite "lib/libcrypt.so"

  def install
    system "./configure", "--disable-static",
                          "--disable-obsolete-api",
                          "--disable-xcrypt-compat-files",
                          "--disable-failure-tokens",
                          "--disable-valgrind",
                          *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <crypt.h>
      #include <errno.h>
      #include <stdio.h>
      #include <string.h>

      int main()
      {
        char *hash = crypt("abc", "$2b$05$abcdefghijklmnopqrstuu");

        if (errno) {
          fprintf(stderr, "Received error: %s", strerror(errno));
          return errno;
        }
        if (hash == NULL) {
          fprintf(stderr, "Hash is NULL");
          return -1;
        }
        if (strcmp(hash, "$2b$05$abcdefghijklmnopqrstuuRWUgMyyCUnsDr8evYotXg5ZXVF/HhzS")) {
          fprintf(stderr, "Unexpected hash output");
          return -1;
        }

        return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lcrypt", "-o", "test"
    system "./test"
  end
end
