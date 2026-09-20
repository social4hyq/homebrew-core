class Structurizr < Formula
  desc "Software architecture models as code"
  homepage "https://structurizr.com/"
  url "https://github.com/structurizr/structurizr/archive/refs/tags/v2026.09.19.tar.gz"
  sha256 "bcf0f09ecd3209c931cce0211f87b914991870364f4321a83c59cf4ecbe40d94"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6e9c2677a92c682bbd1db96997e6cfcc59dc80a85381dbd222545502629a950f"
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
