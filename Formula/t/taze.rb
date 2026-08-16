class Taze < Formula
  desc "Modern cli tool that keeps your deps fresh"
  homepage "https://github.com/antfu-collective/taze"
  url "https://registry.npmjs.org/taze/-/taze-21.1.0.tgz"
  sha256 "1bf46e8a0f36409a694cb22b8a01ca6506f19c8545b089eef601d952f68fa77e"
  license "MIT"
  head "https://github.com/antfu-collective/taze.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7c9e6529f810f9cb96b5323a91e2872c17983b5e7055ec9936486bf585eab3a7"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/taze --version")

    (testpath/"package.json").write <<~JSON
      {
        "name": "brewtest",
        "version": "1.0.0",
        "dependencies": {
          "homebrew-nonexistent": "1.1.0"
        }
      }
    JSON

    output = shell_output("#{bin}/taze 2>&1")
    assert_match "Failed to fetch package \"homebrew-nonexistent\"", output
  end
end
