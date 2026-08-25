class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-16.15.0.tgz"
  sha256 "118d7dfe22f19590128a60d07e43f20c0a7540ef8d31249746c790aaecdd9f62"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "af8f9724613b9a68a78a5ccd7fdb10b191fa65f81be28a6cbdf6ebb68ba2e13b"
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
