class Javacc < Formula
  desc "Parser generator for use with Java applications"
  homepage "https://javacc.github.io/javacc/"
  url "https://github.com/javacc/javacc/archive/refs/tags/javacc-7.0.13.tar.gz"
  sha256 "d1bfebb4ca9261c5c3b16b00280b3278a41b193ca8503f2987f72de453bf99c6"
  license "BSD-3-Clause"
  revision 1

  livecheck do
    url :stable
    regex(/javacc[._-]v?(\d+(?:\.\d+)+)/i)
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a36c4a2f2d95473d53fc47c8c54739c33ed9749c588f80b910e6e26aec8ca9e2"
  end

  depends_on "ant" => :build
  depends_on "openjdk"

  def install
    system "ant"
    libexec.install "target/javacc.jar"
    doc.install Dir["www/doc/*"]
    (share/"examples").install Dir["examples/*"]
    %w[javacc jjdoc jjtree].each do |script|
      (bin/script).write <<~SH
        #!/bin/bash
        export JAVA_HOME="${JAVA_HOME:-#{Formula["openjdk"].opt_prefix}}"
        exec "${JAVA_HOME}/bin/java" -classpath '#{libexec}/javacc.jar' #{script} "$@"
      SH
    end
  end

  test do
    src_file = share/"examples/SimpleExamples/Simple1.jj"

    output_file_stem = testpath/"Simple1"

    system bin/"javacc", src_file
    assert_path_exists output_file_stem.sub_ext(".java")

    system bin/"jjtree", src_file
    assert_path_exists output_file_stem.sub_ext(".jj.jj")

    system bin/"jjdoc", src_file
    assert_path_exists output_file_stem.sub_ext(".html")
  end
end
