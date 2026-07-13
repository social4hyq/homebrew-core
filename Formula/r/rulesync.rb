class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-9.6.3.tgz"
  sha256 "470aebefaae4b74c6a31b509c10287b1863293690ab4bd74cf9597e1a5dbeddc"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8c10eef00967da0631f9b3eb440ceef4d7e7258906709b37d9f4ce8a6539fba9"
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
