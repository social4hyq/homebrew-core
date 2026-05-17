class Sonobuoy < Formula
  desc "Kubernetes component that generates reports on cluster conformance"
  homepage "https://sonobuoy.io/"
  url "https://github.com/vmware-tanzu/sonobuoy/archive/refs/tags/v0.57.4.tar.gz"
  sha256 "5e84f5e4723879b613688ce70522fc0423e5fbe2ada5c341484a60f295715af9"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "54a76044d10b7122e60801d76c20e30a296e424a7aaa53c46e0938160f896f53"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/vmware-tanzu/sonobuoy/pkg/buildinfo.Version=v#{version}"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"sonobuoy", shell_parameter_format: :cobra)
  end

  test do
    assert_match "Sonobuoy is a Kubernetes component that generates reports on cluster conformance",
      shell_output("#{bin}/sonobuoy 2>&1")
    assert_match version.to_s,
      shell_output("#{bin}/sonobuoy version 2>&1")
    assert_match "name: sonobuoy",
      shell_output("#{bin}/sonobuoy gen --kubernetes-version=v1.21 2>&1")
  end
end
