class Kubectx < Formula
  desc "Tool that can switch between kubectl contexts easily and create aliases"
  homepage "https://github.com/ahmetb/kubectx"
  url "https://github.com/ahmetb/kubectx/archive/refs/tags/v0.11.0.tar.gz"
  sha256 "1c8eb6b30c0067f89e5b2f9480865b0e3229a221fadddb644ce192d663c63907"
  license "Apache-2.0"
  head "https://github.com/ahmetb/kubectx.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "34c43d5221479d67eac39843b33f74d00d566258234c2f8ecf25ebf51e525dcb"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=v#{version}"
    system "go", "build", *std_go_args(ldflags:, output: bin/"kubectx"), "./cmd/kubectx"
    system "go", "build", *std_go_args(ldflags:, output: bin/"kubens"), "./cmd/kubens"

    ln_s bin/"kubectx", bin/"kubectl-ctx"
    ln_s bin/"kubens", bin/"kubectl-ns"

    %w[kubectx kubens].each do |cmd|
      bash_completion.install "completion/#{cmd}.bash" => cmd.to_s
      zsh_completion.install "completion/_#{cmd}.zsh" => "_#{cmd}"
      fish_completion.install "completion/#{cmd}.fish"
    end
  end

  test do
    assert_match "USAGE:", shell_output("#{bin}/kubectx -h 2>&1")
    assert_match "USAGE:", shell_output("#{bin}/kubens -h 2>&1")
    assert_match version.to_s, shell_output("#{bin}/kubectx -V")
    assert_match version.to_s, shell_output("#{bin}/kubens -V")
  end
end
