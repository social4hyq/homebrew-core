class Libtpms < Formula
  desc "Library for software emulation of a Trusted Platform Module"
  homepage "https://github.com/stefanberger/libtpms"
  url "https://github.com/stefanberger/libtpms/archive/refs/tags/v0.10.2.tar.gz"
  sha256 "edac03680f8a4a1c5c1d609a10e3f41e1a129e38ff5158f0c8deaedc719fb127"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ecada6ccda5069dac7fe876cd7c006abfcf44d635d3aa8645d92324a28b44745"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "openssl@3"

  def install
    system "./autogen.sh", "--with-openssl", "--with-tpm2", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <libtpms/tpm_library.h>

      int main()
      {
          TPM_RESULT res = TPMLIB_ChooseTPMVersion(TPMLIB_TPM_VERSION_2);
          if (res) {
              TPMLIB_Terminate();
              return 1;
          }
          return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-ltpms", "-o", "test"
    system "./test"
  end
end
