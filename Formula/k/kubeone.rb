class Kubeone < Formula
  desc "Automate cluster operations on all your environments"
  homepage "https://kubeone.io"
  url "https://github.com/kubermatic/kubeone/archive/refs/tags/v1.14.3.tar.gz"
  sha256 "24af68b7971592c95c67517d129098d2a1332bb88d64f8f1d180d07e5e4c1e8c"
  license "Apache-2.0"
  head "https://github.com/kubermatic/kubeone.git", branch: "main"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bae83af4d1e75425418f04f42936a35bd4a6074fb9744da9e32a5a3a5b7cb14a"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X k8c.io/kubeone/pkg/cmd.version=#{version}
      -X k8c.io/kubeone/pkg/cmd.date=#{time.iso8601}
    ]

    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"kubeone", "completion")
  end

  test do
    test_config = testpath/"kubeone.yaml"

    test_config.write <<~YAML
      apiVersion: kubeone.k8c.io/v1beta2
      kind: KubeOneCluster

      versions:
        kubernetes: 1.30.1
    YAML

    assert_match "apiEndpoint.port must be greater than 0", shell_output("#{bin}/kubeone status 2>&1", 15)

    assert_match version.to_s, shell_output("#{bin}/kubeone version")
  end
end
