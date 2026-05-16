class ZshHistorySubstringSearch < Formula
  desc "Zsh port of Fish shell's history search"
  homepage "https://github.com/zsh-users/zsh-history-substring-search"
  url "https://github.com/zsh-users/zsh-history-substring-search/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "9b52eca6c894dd98caa5f07160199f3f3179ff017575d5acc9fdc467b1ac70f8"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "82fb36632e43bcfe508b869f332224e476aa91b3026963a4fb5f09e5f19ab303"
  end

  uses_from_macos "zsh"

  def install
    pkgshare.install "zsh-history-substring-search.zsh"
  end

  def caveats
    <<~EOS
      To activate the history search, add the following at the end of your .zshrc:

        source #{HOMEBREW_PREFIX}/share/zsh-history-substring-search/zsh-history-substring-search.zsh

      You will also need to restart your terminal for this change to take effect.
    EOS
  end

  test do
    assert_match "i",
      shell_output("zsh -c '. #{pkgshare}/zsh-history-substring-search.zsh && " \
                   "echo $HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS'")
  end
end
