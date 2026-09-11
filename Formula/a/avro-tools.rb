class AvroTools < Formula
  desc "Avro command-line tools and utilities"
  homepage "https://avro.apache.org/"
  url "https://www.apache.org/dyn/closer.lua?path=avro/avro-1.12.2/java/avro-tools-1.12.2.jar"
  mirror "https://archive.apache.org/dist/avro/avro-1.12.2/java/avro-tools-1.12.2.jar"
  sha256 "6220e8bc089aaf917cdad4cd358bd651fc0394c0e5ddb8b36da402012c294a68"
  license "Apache-2.0"
  revision 1

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1b19f2d60c0b7ec0e974dda5a841b617ea699d328cbf9bce5a41a0595210c5b5"
  end

  depends_on "openjdk"

  def install
    libexec.install "avro-tools-#{version}.jar"
    bin.write_jar_script libexec/"avro-tools-#{version}.jar", "avro-tools"
  end

  test do
    assert_match "Version #{version}", shell_output("#{bin}/avro-tools 2>&1", 1)
  end
end
