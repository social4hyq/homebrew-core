class Mill < Formula
  desc "Fast, scalable JVM build tool"
  homepage "https://mill-build.org/"
  url "https://search.maven.org/remotecontent?filepath=com/lihaoyi/mill-dist/1.1.6/mill-dist-1.1.6.exe"
  sha256 "37922ae8f8b49b4ae345d9b4d764be235c9afd8039e0b3fc513fdd758904649f"
  license "MIT"

  livecheck do
    url "https://search.maven.org/remotecontent?filepath=com/lihaoyi/mill-dist/maven-metadata.xml"
    regex(%r{<version>v?(\d+(?:\.\d+)+)</version>}i)
  end

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cb4234a040aa4d73d1e7fcb8111b12f2772ef79be6939c928ac0e9be10752388"
  end

  depends_on "openjdk"

  def install
    libexec.install Dir["*"].shift => "mill"
    chmod 0555, libexec/"mill"
    (bin/"mill").write_env_script libexec/"mill", Language::Java.overridable_java_home_env
  end

  test do
    (testpath/"build.sc").write <<~SCALA
      import mill._
      import mill.scalalib._
      object foo extends ScalaModule {
        def scalaVersion = "2.13.11"
      }
    SCALA
    output = shell_output("#{bin}/mill resolve __.compile 2>&1")
    assert_match "SUCCESS", output
  end
end
