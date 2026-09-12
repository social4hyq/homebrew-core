class ApacheOpennlp < Formula
  desc "Machine learning toolkit for processing natural language text"
  homepage "https://opennlp.apache.org/"
  url "https://www.apache.org/dyn/closer.lua?path=opennlp/opennlp-2.5.12/apache-opennlp-2.5.12-bin.tar.gz"
  mirror "https://archive.apache.org/dist/opennlp/opennlp-2.5.12/apache-opennlp-2.5.12-bin.tar.gz"
  sha256 "3d0f4b90257f0a18c7acd7bdab7d9ea96a4870aeb4bf895f07a2feecc476f5a1"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "979692988f899ae863e3142f976c866beb1dfe9ef627f367abdb0187cfec6079"
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
