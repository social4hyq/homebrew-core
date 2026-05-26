class Polypolish < Formula
  desc "Short-read polishing tool for long-read assemblies"
  homepage "https://github.com/rrwick/Polypolish"
  url "https://github.com/rrwick/Polypolish/archive/refs/tags/v0.6.1.tar.gz"
  sha256 "7a9b803aac87a7963c08c162c502f90f9cf93b1f58d1502047eefc43aca65bde"
  license "GPL-3.0-or-later"
  head "https://github.com/rrwick/Polypolish.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a7c3368168057c913b83c62773840ae382b5012a02871e4599adf90fcdf1b1ac"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"test.fasta").write <<~EOS
      >U00096.2:1-70
      AGCTTTTCATTCTGACTGCAACGGGCAATATGTCTCTGTGTGGATTAAAAAAAGAGTGTCTGATAGCAGC
    EOS
    output = shell_output("#{bin}/polypolish polish test.fasta")
    assert_match "polypolish", output
  end
end
