class Lightning < Formula
  desc "Generates assembly language code at run-time"
  homepage "https://www.gnu.org/software/lightning/"
  url "https://ftpmirror.gnu.org/gnu/lightning/lightning-2.2.3.tar.gz"
  mirror "https://ftp.gnu.org/gnu/lightning/lightning-2.2.3.tar.gz"
  sha256 "c045c7a33a00affbfeb11066fa502c03992e474a62ba95977aad06dbc14c6829"
  license "GPL-3.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d6b5177424c9043ff760a07af0a63168f4fbbb3709189d493a2c8f151897f926"
  end

  depends_on "binutils" => :build

  # upstream patch for fixing `Correct wrong ifdef causing missing mprotect call if NDEBUG is not defined`
  patch do
    url "https://cgit.git.savannah.gnu.org/cgit/lightning.git/patch/?id=bfd695a94668861a9447b29d2666f8b9c5dcd5bf"
    sha256 "9264f463ce98e090e1386dd328cf02d542609c6375a6968d4024fbe8a6cabf8b"
  end

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args.reject { |s| s["--disable-debug"] }
    system "make", "install"
  end

  test do
    # from https://www.gnu.org/software/lightning/manual/lightning.html#incr
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <lightning.h>
      static jit_state_t *_jit;
      typedef int (*pifi)(int);
      int main(int argc, char *argv[]) {
        jit_node_t  *in;
        pifi incr;
        init_jit(argv[0]);
        _jit = jit_new_state();
        jit_prolog();
        in = jit_arg();
        jit_getarg(JIT_R0, in);
        jit_addi(JIT_R0, JIT_R0, 1);
        jit_retr(JIT_R0);
        incr = jit_emit();
        jit_clear_state();
        printf("%d + 1 = %d\\n", 5, incr(5));
        jit_destroy_state();
        finish_jit();
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-llightning", "-o", "test"
    system "./test"
  end
end
