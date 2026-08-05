class Aicommits < Formula
  desc "Writes your git commit messages for you with AI"
  homepage "https://github.com/Nutlope/aicommits"
  url "https://registry.npmjs.org/aicommits/-/aicommits-4.0.0.tgz"
  sha256 "ccd6abcf17724a6a4b5a895d23ceb901f78b46713d9e05e930d3465f27218949"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bb827eb10dd96494a1a039d1ce17b19ba6823d9579e5f88568e873be9a382c17"
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
