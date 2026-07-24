class ApacheOpennlp < Formula
  desc "Machine learning toolkit for processing natural language text"
  homepage "https://opennlp.apache.org/"
  url "https://www.apache.org/dyn/closer.lua?path=opennlp/opennlp-2.5.11/apache-opennlp-2.5.11-bin.tar.gz"
  mirror "https://archive.apache.org/dist/opennlp/opennlp-2.5.11/apache-opennlp-2.5.11-bin.tar.gz"
  sha256 "2edb832b02ff0059d5a4d1f03924471e683f4fd8752bfbf2ca33ff84340847ec"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2446a4a07a446ebf660c09ce415250e57fe787c2b5739b2aded024b9a47e3d78"
  end

  depends_on "openjdk"

  def install
    # Remove Windows scripts
    rm(Dir["bin/*.bat"])

    libexec.install Dir["*"]
    (bin/"opennlp").write_env_script libexec/"bin/opennlp", JAVA_HOME:    Formula["openjdk"].opt_prefix,
                                                            OPENNLP_HOME: libexec
  end

  test do
    output = pipe_output("#{bin}/opennlp SimpleTokenizer", "Hello, friends", 0)
    assert_equal "Hello , friends", output.lines.first.chomp
  end
end
