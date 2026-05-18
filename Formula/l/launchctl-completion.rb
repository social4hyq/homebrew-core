class LaunchctlCompletion < Formula
  desc "Bash completion for Launchctl"
  homepage "https://github.com/CamJN/launchctl-completion"
  url "https://github.com/CamJN/launchctl-completion/archive/refs/tags/v2.0.tar.gz"
  sha256 "990499494562cedf361482c5bf9f89b3a8b6a8aee92fda4e1eadaacb96688ecd"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c953d4a330b6c044ed993735695da68cfc221ee5edf0fab0963383aa0604d389"
  end

  def install
    bash_completion.install "launchctl-completion.sh" => "launchctl"
  end

  test do
    assert_match "-F _launchctl",
                 shell_output("bash -c 'source #{bash_completion}/launchctl && complete -p launchctl'")
  end
end
