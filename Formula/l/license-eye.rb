class LicenseEye < Formula
  desc "Tool to check and fix license headers and resolve dependency licenses"
  homepage "https://github.com/apache/skywalking-eyes"
  url "https://www.apache.org/dyn/closer.lua?path=skywalking/eyes/0.8.0/skywalking-license-eye-0.8.0-src.tgz"
  mirror "https://archive.apache.org/dist/skywalking/eyes/0.8.0/skywalking-license-eye-0.8.0-src.tgz"
  sha256 "cd642a1090ad526fa6517c795c9360916bbb15ed483b3ebc3199ddb9a9821a65"
  license "Apache-2.0"
  head "https://github.com/apache/skywalking-eyes.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "660011c392d67836f0e189a086ad0e430b3c20ce3de59a230bbe42ca3054f4cb"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/apache/skywalking-eyes/commands.version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/license-eye"

    generate_completions_from_executable(bin/"license-eye", shell_parameter_format: :cobra)
  end

  test do
    output = shell_output("#{bin}/license-eye dependency check")
    assert_match "Loading configuration from file: .licenserc.yaml", output
    assert_match "Config file .licenserc.yaml does not exist, using the default config", output

    assert_match version.to_s, shell_output("#{bin}/license-eye --version")
  end
end
