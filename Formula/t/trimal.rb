class Trimal < Formula
  desc "Automated alignment trimming in large-scale phylogenetic analyses"
  homepage "https://trimal.readthedocs.io/"
  url "https://github.com/inab/trimal/archive/refs/tags/v1.5.1.tar.gz"
  sha256 "58751054861b152e92214ff8c01a132071230614e8e777a7c9280d03648cde3b"
  license "GPL-3.0-only"
  head "https://github.com/inab/trimal.git", branch: "trimAl"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "85fc16377e68ad75c98ed91e5fa8fe2cd78c280dd489f54a89ff4e4f1bae6d56"
  end

  def install
    cd "source" do
      system "make"
      bin.install "readal", "trimal", "statal"
    end
  end

  test do
    (testpath/"test.fasta").write <<~EOS
      >U00096.2:1-70
      AGCTTTTCATTCTGACTGCAACGGGCAATATGTCTCTGTGTGGATTAAAAAAAGAGTGTCTGATAGCAGC
    EOS
    system bin/"trimal", "-in", "test.fasta", "-out", "out.fasta"
    assert_path_exists "out.fasta"
  end
end
