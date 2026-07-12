class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-9.6.2.tgz"
  sha256 "52d0352c6097def6f81e2314e69e4504875984ad77f54d4ea78a04f561f29761"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "674ddefe47860b89724aeeeb8c7eb35c78973775baa1c9886866afcb4f6a9bbd"
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
