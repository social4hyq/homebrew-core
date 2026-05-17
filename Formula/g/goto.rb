class Goto < Formula
  desc "Bash tool for navigation to aliased directories with auto-completion"
  homepage "https://github.com/iridakos/goto"
  url "https://github.com/iridakos/goto/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "460fe3994455501b50b2f771f999ace77ade295122e90e959084047dbfb1f0dc"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2f5aa87c99f6aeda15b9a8015445c8e95e4229ec889c1338dd80860a10a8f994"
  end

  def install
    bash_completion.install "goto.sh"
  end

  test do
    assert_match "-F _complete_goto_bash",
      shell_output("bash -c 'source #{bash_completion}/goto.sh && complete -p goto'")
  end
end
