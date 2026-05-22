class AvroTools < Formula
  desc "Avro command-line tools and utilities"
  homepage "https://avro.apache.org/"
  url "https://www.apache.org/dyn/closer.lua?path=avro/avro-1.12.1/java/avro-tools-1.12.1.jar"
  mirror "https://archive.apache.org/dist/avro/avro-1.12.1/java/avro-tools-1.12.1.jar"
  sha256 "eb269df172ec96f6721bf9e56182e28afd9cd72d596d035c46561f6f70a69c36"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a4e8a34406c881b64969bf757e8476ee79a902c2ddfeb2e14f7f1ee6cf652365"
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
