class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-16.30.2.tgz"
  sha256 "4347e96d17fae1f99f61bad35a01623281a24e36c6d2ceaae08a000cac7ae854"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "479af7a4cf25e92a812e5c6fb784fb00d104b68216d0445dc84c25b4fd3e5f6a"
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
