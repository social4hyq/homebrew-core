class Kubeaudit < Formula
  desc "Helps audit your Kubernetes clusters against common security controls"
  homepage "https://github.com/Shopify/kubeaudit"
  url "https://github.com/Shopify/kubeaudit/archive/refs/tags/v0.22.2.tar.gz"
  sha256 "90752d42c4d502ab6776af3358ae87a02d2893fc2bb7a0364d6c1fdcd8ff0570"
  license "MIT"
  head "https://github.com/Shopify/kubeaudit.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ebf7cb46c34d41a2c21d5ad95476268eca86bcb0865d61056e75069ab9dab7d8"
  end

  # https://github.com/Shopify/kubeaudit/pull/594
  deprecate! date: "2025-01-10", because: :repo_archived, replacement_formula: "kube-bench"
  disable! date: "2026-01-10", because: :repo_archived, replacement_formula: "kube-bench"

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/Shopify/kubeaudit/cmd.Version=#{version}
      -X github.com/Shopify/kubeaudit/cmd.BuildDate=#{time.strftime("%F")}
    ]

    system "go", "build", *std_go_args(ldflags:), "./cmd"

    generate_completions_from_executable(bin/"kubeaudit", shell_parameter_format: :cobra)
  end

  test do
    output = shell_output("#{bin}/kubeaudit --kubeconfig /some-file-that-does-not-exist all 2>&1", 1).chomp
    assert_match "failed to open kubeconfig file /some-file-that-does-not-exist", output
  end
end
