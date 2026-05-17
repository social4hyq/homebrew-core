class Krew < Formula
  desc "Package manager for kubectl plugins"
  homepage "https://sigs.k8s.io/krew/"
  url "https://github.com/kubernetes-sigs/krew.git",
      tag:      "v0.5.0",
      revision: "8a4a6fffb08d2ee04b4b013253160a50ed22139c"
  license "Apache-2.0"
  head "https://github.com/kubernetes-sigs/krew.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4becf5af9896372bd4223c80d6411213bf87e395319ac9cc0aa952cca08cdb2c"
  end

  depends_on "go" => :build
  depends_on "kubernetes-cli"

  def install
    ENV["CGO_ENABLED"] = "0"

    ldflags = %W[
      -w
      -X sigs.k8s.io/krew/internal/version.gitCommit=#{Utils.git_short_head(length: 8)}
      -X sigs.k8s.io/krew/internal/version.gitTag=v#{version}
    ]

    system "go", "build", *std_go_args(output: bin/"kubectl-krew", ldflags:, tags: "netgo"), "./cmd/krew"
  end

  test do
    ENV["KREW_ROOT"] = testpath
    kubectl = Formula["kubernetes-cli"].opt_bin/"kubectl"

    system bin/"kubectl-krew", "update"
    system bin/"kubectl-krew", "install", "ctx"
    assert_path_exists testpath/"bin/kubectl-ctx"

    assert_match "v#{version}", shell_output("#{bin}/kubectl-krew version")
    assert_match (HOMEBREW_PREFIX/"bin/kubectl-krew").to_s, shell_output("#{kubectl} plugin list")
  end
end
