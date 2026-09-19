class Form < Formula
  desc "Symbolic manipulation system"
  homepage "https://www.nikhef.nl/~form/"
  url "https://github.com/form-dev/form/releases/download/v5.0.2/form-5.0.2.tar.gz"
  sha256 "90a3fbc31a31de50a181e63ce222d0224642a5916fdbb25373913558a6d6921a"
  license "GPL-3.0-or-later"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b1e9d31b7f2bed394cf750bd56b86deea42926d1a35b5159eaf15e5ccb5b490c"
  end

  depends_on "flint"
  depends_on "gmp"
  depends_on "mpfr"
  depends_on "zstd"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "./configure", *std_configure_args, "--disable-silent-rules", "--disable-native"
    system "make", "install"
  end

  test do
    (testpath/"test.frm").write <<~EOS
      Symbol x,n;
      Local E = x^10;

      repeat id x^n?{>1} = x^(n-1) + x^(n-2);

      Print;
      .end
    EOS

    expected_match = /E\s*=\s*34 \+ 55\*x;/
    assert_match expected_match, shell_output("#{bin}/form #{testpath}/test.frm")
    assert_match expected_match, shell_output("#{bin}/tform #{testpath}/test.frm")
  end
end
