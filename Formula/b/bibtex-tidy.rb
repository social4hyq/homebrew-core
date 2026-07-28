class BibtexTidy < Formula
  desc "Cleaner and Formatter for BibTeX files"
  homepage "https://github.com/FlamingTempura/bibtex-tidy"
  url "https://registry.npmjs.org/bibtex-tidy/-/bibtex-tidy-1.15.0.tgz"
  sha256 "cebe51d16c99a9881d33d52fbd477d4c2c808ca01cc33a04e0437e999a352e09"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3a48a95c7bfaced4ff6519a4a9b2b9f1ea29983ffc04e303d99ad62c0b3f2602"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    test_file = testpath/"test.bib"
    test_file.write <<~BIBTEX
      @article{example,
        author = {Author},
        title = {Title},
        year = {2024}
      }
    BIBTEX

    output = shell_output("#{bin}/bibtex-tidy #{test_file}")
    assert_match "Done. Successfully tidied 1 entries.", output
  end
end
