class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-9.1.1.tgz"
  sha256 "64c2560096a7ac7840ca8f9d541254f51bd27f906d6aaaedf3d686c48d6bef6a"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "49eee05ed2e535b8b67b913f02c2832bd0d0d02206a4643b65da86550e856d41"
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
