class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-16.32.1.tgz"
  sha256 "f7f7bb17308b64ae14580f36102846ff3ebef38b221c72461e1d4a528b3f1687"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aea49da67a11821d575a2e106b113dc30ff32f698403232857c9e3cfdd9c8ae9"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/rulesync --version")

    output = shell_output("#{bin}/rulesync init")
    assert_match "rulesync initialized successfully", output
    assert_match "Project overview and general development guidelines", (testpath/".rulesync/rules/overview.md").read
  end
end
