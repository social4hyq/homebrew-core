class BibtexTidy < Formula
  desc "Cleaner and Formatter for BibTeX files"
  homepage "https://github.com/FlamingTempura/bibtex-tidy"
  url "https://registry.npmjs.org/bibtex-tidy/-/bibtex-tidy-1.14.0.tgz"
  sha256 "0a2c1bb73911a7cee36a30ce1fc86feffe39b2d39acd4c94d02aac6f84a00285"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "099cd49a8d84884ad409197c2fc19c6bca3e7a55333f04889ff60c5bd823d846"
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
