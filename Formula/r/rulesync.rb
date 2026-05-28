class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-8.22.0.tgz"
  sha256 "9769edd29ab10d786c73ddc2c7bcf53ea86d06e1bbb59b300270b9501c2ff3de"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1da3bf95735bc8d885355aba344e09adc9601e14862232dfb5905a54aeb5faaa"
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
