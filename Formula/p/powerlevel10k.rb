class Powerlevel10k < Formula
  desc "Theme for zsh"
  homepage "https://github.com/romkatv/powerlevel10k"
  url "https://github.com/romkatv/powerlevel10k/archive/refs/tags/v1.20.0.tar.gz"
  sha256 "d8187d44b697b3a37a8c4896678b4380e717cbf2850179529358348780a2d3d7"
  license "MIT"
  head "https://github.com/romkatv/powerlevel10k.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e67723efd9978a87b95f67c5128de53317a0f8616f13c84c8d2f22724a69f4b6"
  end

  uses_from_macos "zsh" => :test

  def install
    system "make", "pkg"
    pkgshare.install Dir["*"]
  end

  def caveats
    <<~EOS
      To activate this theme, add the following at the end of your .zshrc:

        source #{HOMEBREW_PREFIX}/share/powerlevel10k/powerlevel10k.zsh-theme

      You will also need to restart your terminal for this change to take effect.
    EOS
  end

  test do
    output = shell_output("zsh -fic '. #{pkgshare}/powerlevel10k.zsh-theme && (( ${+P9K_SSH} )) && echo SUCCESS'")
    assert_match "SUCCESS", output
  end
end
