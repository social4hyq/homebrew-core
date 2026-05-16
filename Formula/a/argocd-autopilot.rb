class ArgocdAutopilot < Formula
  desc "Opinionated way of installing Argo CD and managing GitOps repositories"
  homepage "https://argoproj.io"
  url "https://github.com/argoproj-labs/argocd-autopilot.git",
      tag:      "v0.4.20",
      revision: "a1d2d4c97c59d19127b1bfc1eca3149ca0984df9"
  license "Apache-2.0"
  head "https://github.com/argoproj-labs/argocd-autopilot.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "734abc39acd186c60d35557a20b835064e2a22e2ca84fb877f0b81c9e2ad978a"
  end

  depends_on "go" => :build

  def install
    system "make", "cli-package", "DEV_MODE=false"
    bin.install "dist/argocd-autopilot"

    generate_completions_from_executable(bin/"argocd-autopilot", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/argocd-autopilot version")

    assert_match "required flag(s) \\\"git-token\\\" not set\"",
      shell_output("#{bin}/argocd-autopilot repo bootstrap --repo https://github.com/example/repo 2>&1", 1)
  end
end
