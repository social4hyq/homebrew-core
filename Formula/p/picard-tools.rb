class PicardTools < Formula
  desc "Tools for manipulating HTS data and formats"
  homepage "https://broadinstitute.github.io/picard/"
  url "https://github.com/broadinstitute/picard/releases/download/3.5.0/picard.jar"
  sha256 "b7d97861c3a54ba5a421f5a317f38382f955803862d30ef4aca2bcdc54943631"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7563db531aff5e78b1f6829ea3b8ffad6e7111f5040adaabb2934843c4400c2f"
  end

  depends_on "openjdk"

  def install
    libexec.install "picard.jar"
    bin.write_jar_script libexec/"picard.jar", "picard", "$JAVA_OPTS"
  end

  test do
    (testpath/"test.fasta").write <<~EOS
      >U00096.2:1-70
      AGCTTTTCATTCTGACTGCAACGGGCAATATGTCT
      CTGTGTGGATTAAAAAAAGAGTGTCTGATAGCAGC
    EOS
    cmd = "#{bin}/picard NormalizeFasta I=test.fasta O=/dev/stdout"
    assert_match "TCTCTG", shell_output(cmd)
  end
end
