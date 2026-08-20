class Skills < Formula
  desc "Open agent skills ecosystem"
  homepage "https://skills.sh"
  url "https://registry.npmjs.org/skills/-/skills-1.5.23.tgz"
  sha256 "a4ddbadeedfd7aee5e1823c2037b0a313ce4017a8ff1f23b9f7fe30d52a1c963"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "61a9e4af25b4c860fc3871a7231f0cc7e7556cc9ec96250ebeab2e1a2f83c175"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/skills --version")
    assert_match "No project skills found", shell_output("#{bin}/skills list")
    system bin/"skills", "init", "test-skill"
    assert_path_exists testpath/"test-skill/SKILL.md"
  end
end
