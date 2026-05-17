class ScalaAT212 < Formula
  desc "JVM-based programming language"
  homepage "https://www.scala-lang.org/"
  url "https://github.com/scala/scala/releases/download/v2.12.21/scala-2.12.21.tgz"
  mirror "https://www.scala-lang.org/files/archive/scala-2.12.21.tgz"
  sha256 "13bad6399f433ae244e98834aa79f393cb43b46b94ec34662d50d678cb4009ea"
  license "Apache-2.0"

  livecheck do
    url "https://www.scala-lang.org/download/"
    regex(%r{href=.*?download/v?(2\.12(?:\.\d+)+)\.html}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d7745c0b3b1d6ba611a68a5c995819cf7e87ff82afa6b16270daadfd73186c83"
  end

  keg_only :versioned_formula

  depends_on "openjdk"

  def install
    rm(Dir["bin/*.bat"])
    doc.install Dir["doc/*"]
    share.install "man"
    libexec.install "lib"
    prefix.install "bin"
    bin.env_script_all_files libexec/"bin", Language::Java.overridable_java_home_env

    # Set up an IntelliJ compatible symlink farm in 'idea'
    idea = prefix/"idea"
    idea.install_symlink libexec/"src", libexec/"lib"
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
        def main(args: Array[String]) {
          println(s"${2 + 2}")
        }
      }
    SCALA

    out = shell_output("#{bin}/scala -nc #{file}").strip

    assert_equal "4", out
  end
end
