class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-16.23.0.tgz"
  sha256 "3c0cba7631561670c4008c95a8b2034e499f8564f25a9d089718dcb66722337a"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "280e20c853c6e2844384b0893bb4e91a157722ae88ffc13edf4486ceee44ca04"
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
