class Rulesync < Formula
  desc "Unified AI rules management CLI tool"
  homepage "https://github.com/dyoshikawa/rulesync"
  url "https://registry.npmjs.org/rulesync/-/rulesync-16.24.1.tgz"
  sha256 "0a4ce0b144b6403e2714ed94b44afd73ad35d94ae002929a7f8d4bbf31a22ae8"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5faf56b1163803e947130c3d71ec95cf3603a9c3916f14becb9be564c3daf9e6"
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
