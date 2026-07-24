class Skills < Formula
  desc "Open agent skills ecosystem"
  homepage "https://skills.sh"
  url "https://registry.npmjs.org/skills/-/skills-1.5.20.tgz"
  sha256 "359417194b4049eed6b5a80a3c3f57b82c75d48962d791a0efdf41b85cf52990"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fddf1515cf195c2cd6dbacc2faed86604131a04e56db2af7452684f21a211af6"
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
