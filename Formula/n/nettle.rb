class Nettle < Formula
  desc "Low-level cryptographic library"
  homepage "https://www.lysator.liu.se/~nisse/nettle/"
  url "https://ftpmirror.gnu.org/gnu/nettle/nettle-4.0.tar.gz"
  mirror "https://ftp.gnu.org/gnu/nettle/nettle-4.0.tar.gz"
  sha256 "3addbc00da01846b232fb3bc453538ea5468da43033f21bb345cb1e9073f5094"
  license any_of: ["GPL-2.0-or-later", "LGPL-3.0-or-later"]
  revision 1
  compatibility_version 2

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8936c1da0c64c4ca44810cb6ffb1ab015a08f6ffe8e02a25bbd109f947cd2ed7"
  end

  depends_on "gmp"

  uses_from_macos "m4" => :build

  def install
    system "./configure", *std_configure_args, "--enable-shared"
    system "make"
    system "make", "install"
    system "make", "check"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <nettle/sha1.h>
      #include <stdio.h>

      int main()
      {
        struct sha1_ctx ctx;
        uint8_t digest[SHA1_DIGEST_SIZE];
        unsigned i;

        sha1_init(&ctx);
        sha1_update(&ctx, 4, "test");
        sha1_digest(&ctx, digest);

        printf("SHA1(test)=");

        for (i = 0; i<SHA1_DIGEST_SIZE; i++)
          printf("%02x", digest[i]);

        printf("\\n");
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lnettle", "-o", "test"
    system "./test"
  end
end
