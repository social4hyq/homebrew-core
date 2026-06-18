class GmpEcm < Formula
  desc "Elliptic Curve Method for integer factorization"
  homepage "https://gitlab.inria.fr/zimmerma/ecm"
  url "https://gitlab.inria.fr/zimmerma/ecm/-/archive/git-7.0.7/ecm-git-7.0.7.tar.gz"
  sha256 "cfc1c0745694e7b24a8a373d8e854f8ab42cff177dbd98beba3b093e3858ca8a"
  license all_of: ["GPL-3.0-or-later", "LGPL-3.0-or-later"]
  head "https://gitlab.inria.fr/zimmerma/ecm.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "659d1b4a047a857039df485168544849bc8f373ca45934e32da0b7c051f6883f"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "gmp"

  uses_from_macos "m4" => :build

  def install
    system "autoreconf", "--force", "--install"
    system "./configure", "--with-gmp=#{Formula["gmp"].prefix}",
                          "--enable-shared",
                          *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    # Test the ecm binary: factor 121 = 11 * 11
    assert_match "Factor found", pipe_output("#{bin}/ecm 100", "121\n")

    # Test linking against libecm using the P-1 method, which is
    # deterministic: P-1 with B1=5 finds 31 from 3937 = 31 * 127
    # because 31-1 = 30 = 2*3*5 is 5-smooth while
    # 127-1 = 126 = 2*3^2*7 is not.
    (testpath/"test.c").write <<~C
      #include <stdlib.h>
      #include <gmp.h>
      #include <ecm.h>

      int main(void) {
        mpz_t n, f;
        ecm_params q;

        mpz_init_set_ui(n, 3937);
        mpz_init(f);
        ecm_init(q);

        q->method = ECM_PM1;

        int ret = ecm_factor(f, n, 5.0, q);
        if (ret <= 0 || mpz_cmp_ui(f, 31) != 0)
          return 1;

        ecm_clear(q);
        mpz_clear(f);
        mpz_clear(n);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-o", "test",
           "-I#{include}", "-L#{lib}", "-L#{Formula["gmp"].lib}",
           "-lecm", "-lgmp"
    system "./test"
  end
end
