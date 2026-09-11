class Sbuild < Formula
  desc "Scala-based build system"
  homepage "http://sbuild.org/"
  url "https://github.com/SBuild-org/SBuild-org.github.io/raw/master/uploads/sbuild/0.7.7/sbuild-0.7.7-dist.zip"
  sha256 "606bc09603707f31d9ca5bc306ba01b171f8400e643261acd28da7a1a24dfb23"
  license "Apache-2.0"
  revision 3

  livecheck do
    url :homepage
    regex(/href=.*?sbuild[._-]v?(\d+(?:\.\d+)+)(?:[._-]dist)?\.zip/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d15b5fc885bfe1b47bbeac2b570e594eff649a88a933b9758fde80c9c8a50773"
  end

  # https://github.com/SBuild-org/sbuild
  deprecate! date: "2025-12-24", because: :repo_archived
  disable! date: "2026-12-24", because: :repo_archived

  depends_on "openjdk"

  def install
    # Delete unsupported VM option 'MaxPermSize', which is unrecognized in Java 17
    # Remove this line once upstream removes it from bin/sbuild
    inreplace "bin/sbuild", /-XX:MaxPermSize=[^ ]*/, ""

    libexec.install Dir["*"]
    chmod 0755, libexec/"bin/sbuild"
    (bin/"sbuild").write_env_script libexec/"bin/sbuild", Language::Java.overridable_java_home_env
  end

  test do
    expected = <<~SCALA
      import de.tototec.sbuild._

      @version("#{version}")
      class SBuild(implicit _project: Project) {

        Target("phony:clean") exec {
          Path("target").deleteRecursive
        }

        Target("phony:hello") help "Greet me" exec {
          println("Hello you")
        }

      }
    SCALA
    system bin/"sbuild", "--create-stub"
    assert_equal expected, (testpath/"SBuild.scala").read
  end
end
