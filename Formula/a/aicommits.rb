class Aicommits < Formula
  desc "Writes your git commit messages for you with AI"
  homepage "https://github.com/Nutlope/aicommits"
  url "https://registry.npmjs.org/aicommits/-/aicommits-4.1.1.tgz"
  sha256 "a76055878d2c3b89e669b59c8cd2b81316c4400952508d97238f66304fa10aec"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b7a71cf7d3b21be4341862117c3ffcd5a18cdcafaf12f07579226d28f138d249"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match "The current directory must be a Git repository!", shell_output("#{bin}/aicommits 2>&1", 1)

    system "git", "init"
    assert_match "No staged changes found. Stage your changes manually, or automatically stage all changes with the",
      shell_output("#{bin}/aicommits 2>&1", 1)
    touch "test.txt"
    system "git", "add", "test.txt"
    assert_match "No configuration found.", shell_output("#{bin}/aicommits 2>&1", 1)
  end
end
