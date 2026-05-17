class ZshNavigationTools < Formula
  desc "Zsh curses-based tools, e.g. multi-word history searcher"
  homepage "https://wiki.zshell.dev/ecosystem/plugins/zsh-navigation-tools"
  url "https://github.com/z-shell/zsh-navigation-tools/archive/refs/tags/v2.2.7.tar.gz"
  sha256 "ee832b81ce678a247b998675111c66aa1873d72aa33c2593a65626296ca685fc"
  license any_of: ["GPL-3.0-only", "MIT"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "533afb6416f98d240d3bd5b10f9ba28915173809cd1216735a5e7a33cd68b02e"
  end

  uses_from_macos "zsh"

  def install
    # Make the bottles uniform
    inreplace [".config/znt/n-cd.conf", "n-panelize"], "/usr/local", HOMEBREW_PREFIX

    system "make", "install", "PREFIX=#{prefix}"
  end

  def caveats
    <<~EOS
      To run zsh-navigation-tools, add the following at the end of your .zshrc:
        source #{HOMEBREW_PREFIX}/share/zsh-navigation-tools/zsh-navigation-tools.plugin.zsh

      You will also need to restart your terminal for this change to take effect.
    EOS
  end

  test do
    # This compiles package's main file
    # Zcompile is very capable of detecting syntax errors
    cp pkgshare/"n-list", testpath
    system "zsh", "-c", "zcompile n-list"
  end
end
