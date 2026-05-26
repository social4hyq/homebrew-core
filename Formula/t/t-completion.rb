class TCompletion < Formula
  desc "Completion for CLI power tool for Twitter"
  homepage "https://sferik.github.io/t/"
  url "https://github.com/sferik/t-ruby/archive/refs/tags/v5.0.0.tar.gz"
  sha256 "30685de7d87d385a1c74b6ef47732c8b5259fe50f434efd651757e5529cc2fe9"
  license "MIT"
  head "https://github.com/sferik/t-ruby.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "425fc9bfc40de6a7e42838540c3e586fa8090373a7d1102c2ebb61b3ab734eb7"
  end

  def install
    bash_completion.install "legacy/etc/t-completion.sh" => "t"
    zsh_completion.install "legacy/etc/t-completion.zsh" => "_t"
  end

  test do
    assert_match "-F _t",
      shell_output("bash -c 'source #{bash_completion}/t && complete -p t'")
  end
end
