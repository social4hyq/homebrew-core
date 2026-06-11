class Trivy < Formula
  desc "Vulnerability scanner for container images, file systems, and Git repos"
  homepage "https://trivy.dev/"
  url "https://github.com/aquasecurity/trivy/archive/refs/tags/v0.71.1.tar.gz"
  sha256 "fb79664621120e700b89f6a4642204787d43cf24d7cec8f37d8a39d26e8bfa9d"
  license "Apache-2.0"
  compatibility_version 1
  head "https://github.com/aquasecurity/trivy.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "96d999684b945ab5f262f98f48d07716206964e7b96a6616f27def2a2bc99822"
  end

  depends_on "go" => :build

  def install
    ENV["GOEXPERIMENT"] = "jsonv2"

    ldflags = %W[
      -s -w
      -X github.com/aquasecurity/trivy/pkg/version/app.ver=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/trivy"
    (pkgshare/"templates").install Dir["contrib/*.tpl"]

    generate_completions_from_executable(bin/"trivy", shell_parameter_format: :cobra)
  end

  test do
    output = shell_output("#{bin}/trivy image alpine:3.10")
    assert_match(/\(UNKNOWN: \d+, LOW: \d+, MEDIUM: \d+, HIGH: \d+, CRITICAL: \d+\)/, output)

    assert_match version.to_s, shell_output("#{bin}/trivy --version")
  end
end
