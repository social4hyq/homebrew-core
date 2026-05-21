class FzfTab < Formula
  desc "Replace zsh completion selection menu with fzf"
  homepage "https://github.com/Aloxaf/fzf-tab"
  url "https://github.com/Aloxaf/fzf-tab/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "d75ac08c2c8af5a6a0478787b0f11fabbe24951973b7841ae963431e2070ee9a"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f15096efa723f948c032d1de8b92c2c91ed2428c4a50c402820d5cb35aedcaaf"
  end

  uses_from_macos "zsh"

  def install
    pkgshare.install "fzf-tab.zsh", "lib", "modules"
  end

  def caveats
    <<~EOS
      To activate fzf-tab, add the following to your .zshrc:
        source "#{opt_pkgshare}/fzf-tab.zsh"
    EOS
  end

  test do
    assert_path_exists pkgshare/"fzf-tab.zsh"
    system "zsh", "-c", "source #{pkgshare}/fzf-tab.zsh && (( $+functions[fzf-tab-complete] ))"
  end
end
