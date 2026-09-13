class Libtirpc < Formula
  desc "Port of Sun's Transport-Independent RPC library to Linux"
  homepage "https://sourceforge.net/projects/libtirpc/"
  url "https://downloads.sourceforge.net/project/libtirpc/libtirpc/1.3.8/libtirpc-1.3.8.tar.bz2"
  sha256 "8839959bfcc7a0f4c609d8e4f53f1c67ae33de23775ec35beb39ff15adf11920"
  license "BSD-3-Clause"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aa06386c2ae21638d02c13359e4bc6ac23ce8431720d823974bf495500bb0303"
  end

  depends_on "krb5"

  def install
    ENV.append_to_cflags "-D__APPLE_USE_RFC_3542" if OS.mac?
    system "./configure", "--disable-silent-rules", *std_configure_args.reject { |s| s["--disable-debug"] }
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <rpc/rpc.h>
      #include <rpc/xdr.h>
      #include <stdio.h>

      int main() {
        XDR xdr;
        char buf[256];
        xdrmem_create(&xdr, buf, sizeof(buf), XDR_ENCODE);
        int i = 42;
        xdr_destroy(&xdr);
        printf("xdr_int succeeded");
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-I#{include}/tirpc", "-ltirpc", "-o", "test"
    system "./test"
  end
end
