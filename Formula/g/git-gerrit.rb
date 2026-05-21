class GitGerrit < Formula
  desc "Gerrit code review helper scripts"
  homepage "https://github.com/fbzhong/git-gerrit"
  url "https://github.com/fbzhong/git-gerrit/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "433185315db3367fef82a7332c335c1c5e0b05dabf8d4fbeff9ecf6cc7e422eb"
  license "BSD-3-Clause"
  head "https://github.com/fbzhong/git-gerrit.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a15584d66bd6989bc53edce45047bc9f45b6490bed53a470daeba058c37ff7a8"
  end

  conflicts_with "gerrit-tools", because: "both install `gerrit-cherry-pick` binaries"

  def install
    prefix.install "bin"
    bash_completion.install "completion/git-gerrit-completion.bash" => "git-gerrit"
  end

  test do
    system "git", "init"
    system "git", "gerrit", "help"
  end
end
