class Storm < Formula
  include Language::Python::Shebang

  desc "Distributed realtime computation system to process data streams"
  homepage "https://storm.apache.org"
  url "https://www.apache.org/dyn/closer.lua?path=storm/apache-storm-2.8.8/apache-storm-2.8.8.tar.gz"
  mirror "https://archive.apache.org/dist/storm/apache-storm-2.8.8/apache-storm-2.8.8.tar.gz"
  sha256 "170922171ba72a659f7bc5cd68636b3f3e54d208032a9bf9ea01142fe5ce24c2"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2b06be0f562616fd9616789d6f4a3342704a4205e7914d223d21c9a18a30197d"
  end

  depends_on "openjdk"

  uses_from_macos "python"

  def install
    libexec.install Dir["*"]
    (bin/"storm").write_env_script libexec/"bin/storm", Language::Java.overridable_java_home_env
    rewrite_shebang detected_python_shebang(use_python_from_path: true), libexec/"bin/storm.py"
  end

  test do
    system bin/"storm", "version"
  end
end
