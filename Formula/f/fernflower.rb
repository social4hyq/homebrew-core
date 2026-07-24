class Fernflower < Formula
  desc "Advanced decompiler for Java bytecode"
  homepage "https://github.com/JetBrains/fernflower"
  # This project employs synchronized versioning so the sha256 may not change on version bumps
  url "https://www.jetbrains.com/intellij-repository/releases/com/jetbrains/intellij/java/java-decompiler-engine/262.8665.337/java-decompiler-engine-262.8665.337.jar"
  sha256 "2885f0ff6526eb5791367c21055f685b8f9010cb841666cccaec7fc248a6d5e7"
  license "Apache-2.0"

  livecheck do
    url "https://www.jetbrains.com/intellij-repository/releases/com/jetbrains/intellij/java/java-decompiler-engine/maven-metadata.xml"
    regex(%r{<version>v?(\d+(?:\.\d+)+)</version>}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8b164891945f376b09b5829e75cec2bc9f883ddec62b8158ff3e794a9d872213"
  end

  depends_on "openjdk"

  def install
    libexec.install "java-decompiler-engine-#{version}.jar"
    bin.write_jar_script libexec/"java-decompiler-engine-#{version}.jar", "fernflower"
  end

  test do
    (testpath/"Main.java").write <<~JAVA
      void main() {
        IO.println("hello world");
      }
    JAVA

    system Formula["openjdk"].opt_bin/"javac", "Main.java"
    (testpath/"out").mkpath
    system bin/"fernflower", "Main.class", "out"

    output = (testpath/"out/Main.java").read.strip
    expected = <<~JAVA.strip
      final class Main {
         void main() {
            IO.println("hello world");
         }
      }
    JAVA

    assert_equal expected, output
  end
end
