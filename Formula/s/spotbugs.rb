class Spotbugs < Formula
  desc "Tool for Java static analysis (FindBugs's successor)"
  homepage "https://spotbugs.github.io/"
  url "https://repo.maven.apache.org/maven2/com/github/spotbugs/spotbugs/4.10.2/spotbugs-4.10.2.tgz"
  sha256 "63d7687c35fba12cbc8e55ec2a889a2bbf1b9be299dea91f2b0d351dc285308a"
  license "LGPL-2.1-or-later"

  livecheck do
    url "https://repo.maven.apache.org/maven2/com/github/spotbugs/spotbugs/"
    regex(%r{href=["']?v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "362196c00b42f23138184530fba44421cb43907c3da38a664f2b1762da448585"
  end

  head do
    url "https://github.com/spotbugs/spotbugs.git", branch: "master"

    depends_on "gradle" => :build
  end

  depends_on "openjdk"

  conflicts_with "fb-client", because: "both install a `fb` binary"

  def install
    ENV["JAVA_HOME"] = Formula["openjdk"].opt_prefix
    if build.head?
      system "gradle", "build"
      system "gradle", "installDist"
      libexec.install Dir["spotbugs/build/install/spotbugs/*"]
    else
      libexec.install Dir["*"]
      chmod 0755, "#{libexec}/bin/spotbugs"
    end
    (bin/"spotbugs").write_env_script "#{libexec}/bin/spotbugs", Language::Java.overridable_java_home_env
  end

  test do
    (testpath/"HelloWorld.java").write <<~JAVA
      public class HelloWorld {
        private double[] myList;
        public static void main(String[] args) {
          System.out.println("Hello World");
        }
        public double[] getList() {
          return myList;
        }
      }
    JAVA
    system Formula["openjdk"].bin/"javac", "HelloWorld.java"
    system Formula["openjdk"].bin/"jar", "cvfe", "HelloWorld.jar", "HelloWorld", "HelloWorld.class"
    output = shell_output("#{bin}/spotbugs -textui HelloWorld.jar")
    assert_match(/M V EI.*\nM C UwF.*\n/, output)
  end
end
