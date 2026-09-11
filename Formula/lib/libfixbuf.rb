class Libfixbuf < Formula
  desc "Implements the IPFIX Protocol as a C library"
  homepage "https://tools.netsa.cert.org/fixbuf/"
  url "https://tools.netsa.cert.org/releases/libfixbuf-2.5.4.tar.gz"
  sha256 "106b8e1e560928a4dc91d8264326bd2463767570d77417535964f450de1f972e"
  license "LGPL-3.0-only"
  revision 1

  # NOTE: This should be updated to check the main `/fixbuf/download.html`
  # page when it links to a stable version again in the future.
  livecheck do
    url "https://tools.netsa.cert.org/fixbuf2/download.html"
    regex(/["'][^"']*?libfixbuf[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9f42da72cf031bb80ed9bc431adf6ecfc31abed0d47614fd1070b386563a21d0"
  end

  depends_on "pkgconf" => [:build, :test]

  depends_on "glib"
  depends_on "openssl@3"

  on_macos do
    depends_on "gettext"
  end

  def install
    system "./configure", "--with-openssl=#{Formula["openssl@3"].opt_prefix}",
                          "--mandir=#{man}",
                          *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <fixbuf/public.h>
      #include <stdio.h>

      int main() {
          fbInfoModel_t *model = fbInfoModelAlloc();
          if (model == NULL) {
              printf("Failed to allocate InfoModel\\n");
              return 1;
          }

          printf("Successfully allocated InfoModel\\n");
          fbInfoModelFree(model);
          return 0;
      }
    C

    flags = shell_output("pkgconf --cflags --libs libfixbuf").chomp.split
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
