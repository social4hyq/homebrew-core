class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-16.28.0.tgz"
  sha256 "c502fea169de90b1e818aee68d932fb0d8b7139389f94b7c63d6dfef187fe8e9"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "05130648e50768b171165becc6367f9fb80a4574a823cca49320a2a27bd554e5"
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
