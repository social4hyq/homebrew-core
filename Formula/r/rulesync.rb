class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-16.21.0.tgz"
  sha256 "2992d983f5a78789590b2791b5a1eccffe9cea972126297aeb245c18c74a2c52"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ad899874b7df092d4e067e533ca3fe70130a0606036a49a6a363da8281a5b30b"
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
