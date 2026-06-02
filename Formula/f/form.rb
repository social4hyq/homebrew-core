class Form < Formula
  desc "Symbolic manipulation system"
  homepage "https://www.nikhef.nl/~form/"
  url "https://github.com/form-dev/form/releases/download/v5.0.0/form-5.0.0.tar.gz"
  sha256 "10d22acf2f0acf831b494e6a73682828980b9054ea8ec2b5dc46677dca8d6518"
  license "GPL-3.0-or-later"
  revision 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a6c9be5b4d92c88b7bdbb0eb369f714b684d65c19465ce10a9f9c18867021b77"
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
