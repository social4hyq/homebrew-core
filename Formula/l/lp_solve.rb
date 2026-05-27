class LpSolve < Formula
  desc "Mixed integer linear programming solver"
  homepage "https://lp-solve.github.io/"
  url "https://github.com/lp-solve/lp_solve/releases/download/5.5.2.14/lp_solve_5.5.2.14_source.tar.gz"
  sha256 "a4bbdc881128bdbe920a38e134c9add5db47f9aa814a0a018ba940b0f3c278c3"
  license "LGPL-2.1-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c9f349cf9e6da3cb23a3f94323d259cee6bf5ea6b1549cadbe4bf7a6d87f20ea"
  end

  def install
    subdir = if OS.mac?
      target = ".osx"
      "osx64"
    else
      "ux64"
    end

    cd "lpsolve55" do
      system "sh", "ccc#{target}"
      lib.install "bin/#{subdir}/liblpsolve55.a"
      lib.install "bin/#{subdir}/#{shared_library("liblpsolve55")}"
    end

    cd "lp_solve" do
      system "sh", "ccc#{target}"
      bin.install "bin/#{subdir}/lp_solve"
    end

    include.install Dir["*.h"], Dir["shared/*.h"], Dir["bfp/bfp_LUSOL/LUSOL/lusol*.h"]
  end

  test do
    (testpath/"test.lp").write <<~EOS
      max: 143 x + 60 y;

      120 x + 210 y <= 15000;
      110 x + 30 y <= 4000;
      x + y <= 75;
    EOS
    output = shell_output("#{bin}/lp_solve test.lp")
    assert_match "Value of objective function: 6315.6250", output
    assert_match(/x\s+21\.875/, output)
    assert_match(/y\s+53\.125/, output)
  end
end
