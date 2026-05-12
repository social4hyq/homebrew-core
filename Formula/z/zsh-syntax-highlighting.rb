class ZshSyntaxHighlighting < Formula
  desc "Fish shell like syntax highlighting for zsh"
  homepage "https://github.com/zsh-users/zsh-syntax-highlighting"
  url "https://github.com/zsh-users/zsh-syntax-highlighting/archive/refs/tags/0.8.0.tar.gz"
  sha256 "5981c19ebaab027e356fe1ee5284f7a021b89d4405cc53dc84b476c3aee9cc32"
  license "BSD-3-Clause"
  head "https://github.com/zsh-users/zsh-syntax-highlighting.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "edaec4ecd558fd28140f20ff7d8747b58315af9cec2b7681a863243bdd922e8e"
  end

  uses_from_macos "zsh" => [:build, :test]

  def install
    # Make the bottles uniform (modifying a comment with /usr/local path)
    inreplace "highlighters/main/main-highlighter.zsh", "/usr/local/bin", "#{HOMEBREW_PREFIX}/bin"

    system "make", "install", "PREFIX=#{prefix}"
  end

  def caveats
    <<~EOS
      To activate the syntax highlighting, add the following at the end of your .zshrc:
        source #{HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

      If you receive "highlighters directory not found" error message,
      you may need to add the following to your .zshenv:
        export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=#{HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/highlighters
    EOS
  end

  test do
    assert_match "#{version}\n",
      shell_output("zsh -c '. #{pkgshare}/zsh-syntax-highlighting.zsh && echo $ZSH_HIGHLIGHT_VERSION'")
  end
end
