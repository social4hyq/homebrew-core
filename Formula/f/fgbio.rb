class Fgbio < Formula
  desc "Tools for working with genomic and high throughput sequencing data"
  homepage "https://fulcrumgenomics.github.io/fgbio/"
  url "https://github.com/fulcrumgenomics/fgbio/releases/download/4.1.0/fgbio-4.1.0.jar"
  sha256 "6f957bfc4d5fcd56e5e4a4cf63c9d54a6f8603958bc17e8dcb67dec941cfae6f"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4599b0f34f70133b8a8a0debcd04b4b9d57b1281567de74e8cbdd3eb74410e67"
  end

  depends_on "openjdk"

  def install
    libexec.install "fgbio-#{version}.jar"
    bin.write_jar_script libexec/"fgbio-#{version}.jar", "fgbio"
  end

  test do
    (testpath/"test.fasta").write <<~EOS
      >U00096.2:1-70
      AGCTTTTCATTCTGACTGCAACGGGCAATATGTCT
      ctgtgtggattaaaaaaagagtgtctgatagcagc
    EOS
    cmd = "#{bin}/fgbio HardMaskFasta -i test.fasta -o /dev/stdout"
    assert_match "AGCTTTTCATTCTGACTGCAACGGGCAATATGTCTNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN", shell_output(cmd)
  end
end
