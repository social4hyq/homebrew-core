class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-9.0.2.tgz"
  sha256 "cb0d25544f654014d70d09822d23250eae3471fabbac7eddb2f412688ffc42cd"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d6a433d69cc993d6af7664c347cff960947665be92fc29ed880b5e349ae5ad99"
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
