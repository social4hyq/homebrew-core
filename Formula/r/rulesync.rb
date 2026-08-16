class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-16.12.0.tgz"
  sha256 "8510c005452485ca428002eab8732e85add26be9b31625639bc47ee039d55d54"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ab510984aa1adb10c2f3f88478cf2e0f91ed9d3261fa2b19241e36ed35a9c1f3"
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
