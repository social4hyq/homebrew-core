class Structurizr < Formula
  desc "Software architecture models as code"
  homepage "https://structurizr.com/"
  url "https://github.com/structurizr/structurizr/archive/refs/tags/v2026.06.28.tar.gz"
  sha256 "491a857f41b0378ee3c757e39a2fc45eb0fc4c22d48395b5e154380e478c828c"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f1ef8a528ef41bd91b7a44b7ce5adbc84746a4c3383212ee13474531ac1ecfba"
  end

  depends_on "maven" => :build
  depends_on "openjdk"

  def install
    system "mvn", "-Dapp.revision=#{version}", "-Dmaven.test.skip=true", "package"
    libexec.install "structurizr-application/target/structurizr-#{version}.war"
    libexec.install "structurizr-mcp/target/structurizr-mcp-#{version}.war"
    bin.write_jar_script libexec/"structurizr-#{version}.war", "structurizr"
    bin.write_jar_script libexec/"structurizr-mcp-#{version}.war", "structurizr-mcp"
    # NOTE: excluding structurizr-themes due to unknown license for PNG files
  end

  test do
    result = shell_output("#{bin}/structurizr validate -w /dev/null", 1)
    assert_match "/dev/null is not a JSON or DSL file", result

    assert_match "structurizr: #{version}", shell_output("#{bin}/structurizr version")
  end
end
