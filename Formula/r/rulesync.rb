class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-8.31.0.tgz"
  sha256 "2a84a3141f406e21c10a0f4a35c9072842e3fb05a0d0ada85a480f407cb48563"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "42fda2c3cf1f87df9762f488dd19906ebe52ab6f10102e7f2d64b8b19c2524f5"
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
