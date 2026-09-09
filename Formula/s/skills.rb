class Skills < Formula
  desc "Open agent skills ecosystem"
  homepage "https://skills.sh"
  url "https://registry.npmjs.org/skills/-/skills-1.5.25.tgz"
  sha256 "5113db6c999c4c1ce2e63e5f5e96f1b4eec43843feb770d0d2bd95ef58c82203"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0e97b467c839957d868e575b1c5fe57bb1f09c3dee4cbec61b251480ada6241e"
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
