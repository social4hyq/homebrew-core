class Latexdiff < Formula
  desc "Compare and mark up LaTeX file differences"
  homepage "https://www.ctan.org/pkg/latexdiff"
  url "https://github.com/ftilmann/latexdiff/releases/download/1.4.0/latexdiff-1.4.0.tar.gz"
  sha256 "2aaea10ae1a9c1b975c9dc933da6ac6f83f665eea76b358daf86b97b606912ea"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "35a2a6845dedc87f82637512528bb023e0fca4859a8f6ecec07316c3291e4d36"
  end

  uses_from_macos "perl"

  def install
    bin.install %w[latexdiff-fast latexdiff-so latexdiff-vc latexrevise]
    man1.install %w[latexdiff-vc.1 latexdiff.1 latexrevise.1]
    doc.install Dir["doc/*"]
    pkgshare.install %w[contrib example]

    # Install latexdiff-so (with inlined Algorithm::Diff) as the
    # preferred version, more portable
    bin.install_symlink "latexdiff-so" => "latexdiff"
  end

  test do
    (testpath/"test1.tex").write <<~'TEX'
      \documentclass{article}
      \begin{document}
      Hello, world.
      \end{document}
    TEX

    (testpath/"test2.tex").write <<~'TEX'
      \documentclass{article}
      \begin{document}
      Goodnight, moon.
      \end{document}
    TEX

    expect = /^\\DIFdelbegin \s+
             \\DIFdel      \{ Hello,[ ]world \}
             \\DIFdelend   \s+
             \\DIFaddbegin \s+
             \\DIFadd      \{ Goodnight,[ ]moon \}
             \\DIFaddend   \s+
             \.$/x
    assert_match expect, shell_output("#{bin}/latexdiff test[12].tex")
  end
end
