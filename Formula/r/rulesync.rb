class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-16.38.0.tgz"
  sha256 "c0da58662a453122bf78a6ce9f4bbf2729fbeadbf7701b5418fc8f5e300d9bf0"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "964b737e0b3b0fa49dcecd8037e376bdf6f5883955b44c6b799cecb1548c201d"
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
