class ApacheOpennlp < Formula
  desc "Machine learning toolkit for processing natural language text"
  homepage "https://opennlp.apache.org/"
  url "https://www.apache.org/dyn/closer.lua?path=opennlp/opennlp-2.5.10/apache-opennlp-2.5.10-bin.tar.gz"
  mirror "https://archive.apache.org/dist/opennlp/opennlp-2.5.10/apache-opennlp-2.5.10-bin.tar.gz"
  sha256 "0b9de6d1acb6f5ab3bd8eb00e46f120341295e7d6d5aca46fef9debc304675b8"
  license "Apache-2.0"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f30082422c2f0fabbb5cafd427767cc8d91ed568c7112d9a3316414eb7064be9"
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
