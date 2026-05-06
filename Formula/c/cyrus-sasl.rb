class CyrusSasl < Formula
  desc "Simple Authentication and Security Layer"
  homepage "https://www.cyrusimap.org/sasl/"
  url "https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-2.1.28/cyrus-sasl-2.1.28.tar.gz"
  sha256 "7ccfc6abd01ed67c1a0924b353e526f1b766b21f42d4562ee635a8ebfc5bb38c"
  license "BSD-3-Clause-Attribution"
  revision 2

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f334d8483ac802c47b914decf7f547570a5b38ae790440b0b00ccae2d57ae1d7"
  end

  keg_only :provided_by_macos

  depends_on "krb5"
  depends_on "openssl@3"

  uses_from_macos "libxcrypt"

  patch do
    url "https://raw.gitcode.com/Harmonybrew/homebrew-core/raw/main/Patches/cyrus-sasl/0001-add-ohos-support.patch"
    sha256 "d49d45e4df9dd2a9192a5398033ccd4a30a4fa98bd35cf39a7f2ee2d9509edc0"
  end

  def install
    system "./configure",
      "--disable-macos-framework",
      "--disable-dependency-tracking",
      "--disable-silent-rules",
      "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <sasl/saslutil.h>
      #include <assert.h>
      #include <stdio.h>
      int main(void) {
        char buf[123] = "\\0";
        unsigned len = 0;
        int ret = sasl_encode64("Hello, world!", 13, buf, sizeof buf, &len);
        assert(ret == SASL_OK);
        printf("%u %s", len, buf);
        return 0;
      }
    CPP

    system ENV.cxx, "-o", "test", "test.cpp", "-I#{include}", "-L#{lib}", "-lsasl2"
    assert_equal "20 SGVsbG8sIHdvcmxkIQ==", shell_output("./test")
  end
end
