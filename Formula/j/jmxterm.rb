class Jmxterm < Formula
  desc "Open source, command-line based interactive JMX client"
  homepage "https://docs.cyclopsgroup.org/jmxterm"
  url "https://github.com/jiaqi/jmxterm/releases/download/v1.0.4/jmxterm-1.0.4-uber.jar"
  sha256 "ce3e78c732a8632f084f8114d50ca5022cef4a69d68a74b45f5007d34349872b"
  license "Apache-2.0"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "08548814eb5246db1fa88cc8502fedb170f72f6a975c496b9e99ab85db04fb53"
  end

  depends_on "openjdk"

  def install
    libexec.install "jmxterm-#{version}-uber.jar"
    bin.write_jar_script libexec/"jmxterm-#{version}-uber.jar", "jmxterm", ""
  end

  test do
    assert_match(/"software\.name".=."jmxterm";/, pipe_output("#{bin}/jmxterm -n", "about"))
  end
end
