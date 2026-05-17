class BibTool < Formula
  desc "Manipulates BibTeX databases"
  homepage "https://www.gerd-neugebauer.de/software/TeX/BibTool/en/"
  url "https://github.com/ge-ne/bibtool/releases/download/BibTool_2_68/BibTool-2.68.tar.gz"
  sha256 "e1964d199b0726f431f9a1dc4ff7257bb3dba879b9fa221803e0aa7840dee0e0"
  license "GPL-2.0-or-later"

  livecheck do
    url :stable
    regex(/^BibTool[._-]v?(\d+(?:[._-]\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.map { |tag| tag[regex, 1]&.tr("_", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "996ae4dfd4909c0314e1a6b1ca87bb7d70bf2b2f337a56a5012f24788bb3c0d0"
  end

  def install
    system "./configure", "--prefix=#{prefix}", "--without-kpathsea"
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.bib").write <<~BIBTEX
      @article{Homebrew,
          title   = {Something},
          author  = {Someone},
          journal = {Something},
          volume  = {1},
          number  = {2},
          pages   = {3--4}
      }
    BIBTEX

    system bin/"bibtool", "test.bib"
  end
end
