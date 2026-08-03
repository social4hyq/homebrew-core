class Secp256k1 < Formula
  desc "Optimized C library for EC operations on curve secp256k1"
  homepage "https://github.com/bitcoin-core/secp256k1"
  url "https://github.com/bitcoin-core/secp256k1/archive/refs/tags/v0.8.0.tar.gz"
  sha256 "eb52b0e9239dff7dc26be5f9623567141b8720ec47da29eb3c1e0a660d17c8bb"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a35772bdef8410c1ce4d7546026368958c265bf02b7cfa1a4dad8cd919247990"
  end

  depends_on "autoconf" => [:build]
  depends_on "automake" => [:build]
  depends_on "libtool" => [:build]

  def install
    system "./autogen.sh"
    args = %w[
      --disable-silent-rules
      --enable-module-recovery
      --enable-module-ecdh
      --enable-module-schnorrsig
      --enable-module-extrakeys
    ]
    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <secp256k1.h>
      int main() {
        secp256k1_context* ctx = secp256k1_context_create(SECP256K1_CONTEXT_NONE);
        secp256k1_context_destroy(ctx);
        return 0;
      }
    C
    system ENV.cc, "test.c",
                   "-L#{lib}", "-lsecp256k1",
                   "-o", "test"
    system "./test"
  end
end
