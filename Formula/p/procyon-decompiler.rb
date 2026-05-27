class ProcyonDecompiler < Formula
  desc "Modern decompiler for Java 5 and beyond"
  homepage "https://github.com/mstrobel/procyon"
  url "https://github.com/mstrobel/procyon/releases/download/v0.6.0/procyon-decompiler-0.6.0.jar"
  sha256 "821da96012fc69244fa1ea298c90455ee4e021434bc796d3b9546ab24601b779"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6c054f87127d1123b8ff454a8ea341ee8872c834d32cbb54fa4b5f471d14a806"
  end

  depends_on "openjdk@21"

  def install
    libexec.install "procyon-decompiler-#{version}.jar"
    bin.write_jar_script libexec/"procyon-decompiler-#{version}.jar", "procyon-decompiler", java_version: "21"
  end

  test do
    fixture = <<~JAVA
      class T
      {
          public static void main(final String[] array) {
              System.out.println("Hello World!");
          }
      }
    JAVA

    (testpath/"T.java").write fixture
    system Formula["openjdk@21"].bin/"javac", "T.java"
    assert_match fixture, shell_output("#{bin}/procyon-decompiler T.class")
  end
end
