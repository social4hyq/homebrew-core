class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-8.20.0.tgz"
  sha256 "6fe135a6da230637110785ef649e77648fe4c3df1751de00c1ce9162a7bfe121"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "25af4ea5c577a3f4600ab11633e635a49e5b26ad804a619f3cc05384fe9fa9b8"
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
