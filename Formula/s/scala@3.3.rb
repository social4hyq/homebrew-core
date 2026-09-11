class ScalaAT33 < Formula
  desc "JVM-based programming language"
  homepage "https://www.scala-lang.org/"
  url "https://github.com/scala/scala3/releases/download/3.3.8/scala3-3.3.8.tar.gz"
  sha256 "17a03dd9c2a790b4230a7d03b741cdedca6514096e50e7189bc5e2d299db250a"
  license "Apache-2.0"
  revision 1

  livecheck do
    url "https://www.scala-lang.org/download/"
    regex(%r{href=.*?download/v?(3\.3(?:\.\d+)+)\.html}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d01e29924d1376c420fd18890d71b77d4d5d5e997a41fab2fe6e96b8631c3fca"
  end

  keg_only :versioned_formula

  depends_on "openjdk"

  def install
    rm Dir["bin/*.bat"]
    libexec.install "lib"
    prefix.install "bin"
    bin.env_script_all_files libexec/"bin", Language::Java.overridable_java_home_env

    # Set up an IntelliJ compatible symlink farm in 'idea'
    idea = prefix/"idea"
    idea.install_symlink libexec/"lib"
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
