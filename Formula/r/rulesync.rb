class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-8.28.1.tgz"
  sha256 "01463328c08de5a1f07da428566c5bda8b306a0da68b1afebbaabb83b803b8ba"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "64fea9617c3c4d086c9f1ce09b7ed28c9df54ed785a2cc169eda3fd60b80dad8"
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
