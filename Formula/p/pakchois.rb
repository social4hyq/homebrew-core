class Pakchois < Formula
  desc "PKCS #11 wrapper library"
  homepage "https://www.manyfish.co.uk/pakchois/"
  url "https://www.manyfish.co.uk/pakchois/pakchois-0.4.tar.gz"
  sha256 "d73dc5f235fe98e4d1e8c904f40df1cf8af93204769b97dbb7ef7a4b5b958b9a"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?pakchois[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dde769e159407aa8fbc481f65718b2033d094279f433363ba4e40395d94478fd"
  end

  def install
    # Fix flat namespace usage
    inreplace "configure", "${wl}-flat_namespace ${wl}-undefined ${wl}suppress", "${wl}-undefined ${wl}dynamic_lookup"

    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <pakchois/pakchois.h>
      #include <stdio.h>

      int main(void) {
        pakchois_module_t *mod = NULL;

        // load non-existent module
        ck_rv_t rv = pakchois_module_load(&mod, "nonexistent-module");
        printf("pakchois_module_load returned: %lu\\n", rv);

        if (rv != 0) {
          printf("Module load failed as expected\\n");
        }

        if (mod != NULL) {
          pakchois_module_destroy(mod);
        }

        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lpakchois", "-o", "test"
    assert_match "Module load failed as expected", shell_output("./test")
  end
end
