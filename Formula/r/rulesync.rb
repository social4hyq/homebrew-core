class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-16.21.0.tgz"
  sha256 "2992d983f5a78789590b2791b5a1eccffe9cea972126297aeb245c18c74a2c52"
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
