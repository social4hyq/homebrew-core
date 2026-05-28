class Yices2 < Formula
  desc "Yices SMT Solver"
  homepage "https://yices.csl.sri.com/"
  url "https://github.com/SRI-CSL/yices2/archive/refs/tags/yices-2.7.0.tar.gz"
  sha256 "584db72abf6643927b2c3ba98ff793f602216b452b8ff2f34a8851d35904804a"
  license "GPL-3.0-only"
  head "https://github.com/SRI-CSL/yices2.git", branch: "master"

  livecheck do
    url :stable
    regex(/^Yices[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8cee73a19bf0b09408c33aeb7a8b6b65dd5779c52f607d752fac4fb3bdfebde7"
  end

  depends_on "autoconf" => :build
  depends_on "gperf" => :build
  depends_on "gmp"

  def install
    system "autoconf"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"lra.smt2").write <<~EOF
      ;; QF_LRA = Quantifier-Free Linear Real Arithmetic
      (set-logic QF_LRA)
      ;; Declare variables x, y
      (declare-fun x () Real)
      (declare-fun y () Real)
      ;; Find solution to (x + y > 0), ((x < 0) || (y < 0))
      (assert (> (+ x y) 0))
      (assert (or (< x 0) (< y 0)))
      ;; Run a satisfiability check
      (check-sat)
      ;; Print the model
      (get-model)
    EOF
    output = shell_output("#{bin}/yices-smt2 #{testpath}/lra.smt2")
    assert_match "sat\n((define-fun x () Real 2.0)\n (define-fun y () Real (- 1.0)))\n", output
  end
end
