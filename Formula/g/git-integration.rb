class GitIntegration < Formula
  desc "Manage git integration branches"
  homepage "https://johnkeeping.github.io/git-integration/"
  url "https://github.com/johnkeeping/git-integration/archive/refs/tags/v0.4.tar.gz"
  sha256 "b0259e90dca29c71f6afec4bfdea41fe9c08825e740ce18409cfdbd34289cc02"
  license "GPL-2.0-only"
  head "https://github.com/johnkeeping/git-integration.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4970df7396af0945e15d1ba30802b027aac6d133db8349b3a789377478b39f65"
  end

  def install
    (buildpath/"config.mak").write "prefix = #{prefix}"
    system "make", "install"
    system "make", "install-completion"
  end

  test do
    system "git", "config", "--global", "init.defaultBranch", "master"
    system "git", "init"
    system "git", "config", "user.name", "BrewTestBot"
    system "git", "config", "user.email", "BrewTestBot@test.com"
    system "git", "commit", "--allow-empty", "-m", "An initial commit"
    system "git", "checkout", "-b", "branch-a", "master"
    system "git", "commit", "--allow-empty", "-m", "A commit on branch-a"
    system "git", "checkout", "-b", "branch-b", "master"
    system "git", "commit", "--allow-empty", "-m", "A commit on branch-b"
    system "git", "checkout", "master"
    system "git", "integration", "--create", "integration"
    system "git", "integration", "--add", "branch-a"
    system "git", "integration", "--add", "branch-b"
    system "git", "integration", "--rebuild"
  end
end
