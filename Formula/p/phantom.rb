class Phantom < Formula
  desc "CLI tool for seamless parallel development with Git worktrees"
  homepage "https://github.com/phantompane/phantom"
  url "https://registry.npmjs.org/@phantompane/cli/-/cli-6.2.0.tgz"
  sha256 "029984fe5da130d4168f2065c692becccba2ccb7ca73dd118b1b4a870e773852"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "80f46ccf9432bfdf30565a2178fac48f368dd3d7b625487b93e16fe69c9596f9"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    generate_completions_from_executable(bin/"phantom", "completion", shells: [:fish, :zsh])
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/phantom --version")

    system "git", "init"
    system "git", "config", "user.name", "BrewTestBot"
    system "git", "config", "user.email", "BrewTestBot@example.com"

    (testpath/"README.md").write "homebrew-test"
    system "git", "add", "--all"
    system "git", "commit", "-m", "Initial commit"

    system bin/"phantom", "create", "test-worktree"

    assert_match(/\btest-worktree\b/, shell_output("#{bin}/phantom list"))

    worktree_path = testpath/".git/phantom/worktrees/test-worktree"
    assert_equal worktree_path.to_s, shell_output("#{bin}/phantom exec test-worktree pwd").chomp

    system bin/"phantom", "delete", "test-worktree"
    refute_match(/\btest-worktree\b/, shell_output("#{bin}/phantom list"))
  end
end
