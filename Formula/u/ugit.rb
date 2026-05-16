class Ugit < Formula
  desc "Undo git commands. Your damage control git buddy"
  homepage "https://bhupesh.me/undo-your-last-git-mistake-with-ugit/"
  url "https://github.com/Bhupesh-V/ugit/archive/refs/tags/v5.9.tar.gz"
  sha256 "f93d9d4bb0d6fd676704e45733190413885c859ff2807b84cc8113bf674fc063"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "82381d8cfded063ca7a43cfecf35c08092a423db9901e120a083a4676679c370"
  end

  depends_on "fzf"

  on_macos do
    depends_on "bash"
  end

  conflicts_with "git-extras", because: "both install `git-undo` binaries"

  def install
    bin.install "ugit"
    bin.install "git-undo"
  end

  test do
    assert_match "ugit version #{version}", shell_output("#{bin}/ugit --version")
    assert_match "Ummm, you are not inside a Git repo", shell_output(bin/"ugit")
  end
end
