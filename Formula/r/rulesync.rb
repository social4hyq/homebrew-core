class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-16.39.1.tgz"
  sha256 "2b2af99053546b424eae74adbe4521ab82898d914023d13ccca9d950436c21a4"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4d959b9eaafd0100b04d32d5928f179f8193efe565de596d5cb978f185727228"
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
