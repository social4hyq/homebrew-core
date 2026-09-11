class ScalaAT213 < Formula
  desc "JVM-based programming language"
  homepage "https://www.scala-lang.org/"
  url "https://github.com/scala/scala/releases/download/v2.13.18/scala-2.13.18.tgz"
  mirror "https://www.scala-lang.org/files/archive/scala-2.13.18.tgz"
  sha256 "1834d09fd5c78ec77e9a933ab76c724280a8ec9595a332a6112823787a9ac3e6"
  license "Apache-2.0"
  revision 1

  livecheck do
    url "https://www.scala-lang.org/download/"
    regex(%r{href=.*?download/v?(2\.13(?:\.\d+)+)\.html}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bbfe8929230bdd9fc4b23e5e3e4cad46133e88be87786ad38ec98141b42548ea"
  end

  keg_only :versioned_formula

  depends_on "openjdk"

  def install
    rm Dir["bin/*.bat"]
    doc.install (buildpath/"doc").children
    share.install "man"
    libexec.install "lib"
    prefix.install "bin"
    bin.env_script_all_files libexec/"bin", Language::Java.overridable_java_home_env

    # Set up an IntelliJ compatible symlink farm in 'idea'
    idea = prefix/"idea"
    idea.install_symlink libexec/"lib"
    idea.install_symlink doc => "doc"
  end

  def caveats
    <<~EOS
      To use with IntelliJ, set the Scala home to:
        #{opt_prefix}/idea
    EOS
  end

  test do
    file = testpath/"Test.scala"
    file.write <<~SCALA
      object Test {
        def main(args: Array[String]): Unit = {
          println(s"${2 + 2}")
        }
      }
    SCALA

    out = shell_output("#{bin}/scala #{file}").strip

    assert_equal "4", out
  end
end
