class RobloxTs < Formula
  desc "TypeScript-to-Luau Compiler for Roblox"
  homepage "https://roblox-ts.com/"
  url "https://registry.npmjs.org/roblox-ts/-/roblox-ts-3.0.0.tgz"
  sha256 "94e7ee8db40d0fab605601312838ca8d6d72242e78a8f01e02467f53c4232757"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "10471eed43744aa59a088cbc688f6f2dae82f48cf581712cc6878534cf4fd022"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    output = shell_output("#{bin}/rbxtsc 2>&1", 1)
    assert_match "Unable to find tsconfig.json", output

    assert_match version.to_s, shell_output("#{bin}/rbxtsc --version")
  end
end
