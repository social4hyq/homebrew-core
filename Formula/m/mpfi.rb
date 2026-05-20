class Mpfi < Formula
  desc "Multiple precision interval arithmetic library"
  homepage "https://perso.ens-lyon.fr/nathalie.revol/software.html"
  url "https://perso.ens-lyon.fr/nathalie.revol/softwares/mpfi-1.5.4.tar.bz2"
  sha256 "d20ba56a8d57d0816f028be8b18a4aa909a068efcb9a260e69577939e4199752"
  license all_of: ["GPL-3.0-or-later", "LGPL-2.1-or-later"]

  livecheck do
    url :homepage
    regex(/href=.*?mpfi[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "253910a109f46e52e8747a10fbdf3fcec8df0f47bf12f97b03a6fab04f978bb3"
  end

  depends_on "gmp"
  depends_on "mpfr"

  def install
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <mpfi.h>

      int main()
      {
        mpfi_t x;
        mpfi_init(x);
        mpfi_clear(x);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-o", "test",
                   "-L#{lib}", "-lmpfi",
                   "-L#{Formula["mpfr"].lib}", "-lmpfr",
                   "-L#{Formula["gmp"].lib}", "-lgmp"
    system "./test"
  end
end
