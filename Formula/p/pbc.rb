class Pbc < Formula
  desc "Pairing-based cryptography"
  homepage "https://crypto.stanford.edu/pbc/"
  url "https://crypto.stanford.edu/pbc/files/pbc-1.0.0.tar.gz"
  sha256 "18275a367283077bafe35f443200499e3b19c4a3754953da2a1b2f0d6b5922dc"
  license "LGPL-3.0-only"

  livecheck do
    url "https://crypto.stanford.edu/pbc/download.html"
    regex(/href=.*?pbc[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "51b4121b9ca2150dcbd9f07fa02964a247469ece4738cd24b6e94f4b1f36bdcb"
  end

  head do
    url "https://repo.or.cz/pbc.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "gmp"

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build

  def install
    # fix flex yywrap function detection issue
    ENV["ac_cv_search_yywrap"] = "yes"

    system "./setup" if build.head?
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <pbc/pbc.h>
      #include <assert.h>

      int main()
      {
        pbc_param_t param;
        pairing_t pairing;
        element_t g1, g2, gt1, gt2, gt3, a, g1a;
        pbc_param_init_a_gen(param, 160, 512);
        pairing_init_pbc_param(pairing, param);
        element_init_G1(g1, pairing);
        element_init_G2(g2, pairing);
        element_init_G1(g1a, pairing);
        element_init_GT(gt1, pairing);
        element_init_GT(gt2, pairing);
        element_init_GT(gt3, pairing);
        element_init_Zr(a, pairing);
        element_random(g1); element_random(g2); element_random(a);
        element_pairing(gt1, g1, g2); // gt1 = e(g1, g2)
        element_pow_zn(g1a, g1, a); // g1a = g1^a
        element_pow_zn(gt2, gt1, a); // gt2 = gt1^a = e(g1, g2)^a
        element_pairing(gt3, g1a, g2); // gt3 = e(g1a, g2) = e(g1^a, g2)
        assert(element_cmp(gt2, gt3) == 0); // assert gt2 == gt3
        element_clear(g1); element_clear(g2); element_clear(gt1);
        element_clear(gt2); element_clear(gt3); element_clear(a);
        element_clear(g1a);
        pairing_clear(pairing);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{Formula["gmp"].lib}", "-lgmp", "-L#{lib}",
                   "-lpbc", "-o", "test"
    system "./test"
  end
end
