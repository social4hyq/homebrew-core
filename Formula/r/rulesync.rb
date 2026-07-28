class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-15.1.0.tgz"
  sha256 "c8637f827c8fdb9700f905fbc7c16e3d5b3fcb6ad5e42290c48ab33ac2220109"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "01ee11ec72a7a48040e4fe12671a7059f73828112329ece3b67d49c41cac8654"
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
