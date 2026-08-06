class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-16.7.0.tgz"
  sha256 "1a03d251969634623a21b460e20c109c45d27ac5a46c5b3b589e3b97f9d88780"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3111e5adcdbdd0c3dba6a963b724eee2541716bc293317be74497a55e87a9227"
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
