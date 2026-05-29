class Pulumictl < Formula
  desc "Swiss army knife for Pulumi development"
  homepage "https://github.com/pulumi/pulumictl"
  url "https://github.com/pulumi/pulumictl/archive/refs/tags/v0.0.50.tar.gz"
  sha256 "5950c1e147480068cf292f0e6d68bdf38a31be971ec8dad2f6052963d3fe5eb2"
  license "Apache-2.0"
  head "https://github.com/pulumi/pulumictl.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dea1ce93f1ed30f42a4765dfe3e6daf416521b9babf5f654d93dec98b58f8974"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/pulumi/pulumictl/pkg/version.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/pulumictl"

    generate_completions_from_executable(bin/"pulumictl", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/pulumictl version")

    output = shell_output("#{bin}/pulumictl convert-version --language generic --version v1.2.3")
    assert_equal "1.2.3", output.strip

    output = shell_output("#{bin}/pulumictl create homebrew-bump v1.0.0 test-repo --org test-org 2>&1", 1)
    assert_match "Error: unable to create dispatch event", output.strip
  end
end
