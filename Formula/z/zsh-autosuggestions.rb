class ZshAutosuggestions < Formula
  desc "Fish-like fast/unobtrusive autosuggestions for zsh"
  homepage "https://github.com/zsh-users/zsh-autosuggestions"
  url "https://github.com/zsh-users/zsh-autosuggestions/archive/refs/tags/v0.7.1.tar.gz"
  sha256 "0df7affff21cd87ed298e6a3970ed08a1dd66a6efa676454ee5b091ad503badf"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "55245fb91fff46775edd07335d527bfd35ed5e67a77c0a8d7c527d61bbd27e01"
  end

  uses_from_macos "zsh" => :test

  def install
    pkgshare.install "zsh-autosuggestions.zsh"
  end

  def caveats
    <<~EOS
      To activate the autosuggestions, add the following at the end of your .zshrc:

        source #{HOMEBREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

      You will also need to restart your terminal for this change to take effect.
    EOS
  end

  test do
    assert_match "history",
      shell_output("zsh -c '. #{pkgshare}/zsh-autosuggestions.zsh && echo $ZSH_AUTOSUGGEST_STRATEGY'")
  end
end
