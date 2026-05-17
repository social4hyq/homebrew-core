class ClaudeHooks < Formula
  desc "Hook system for Claude Code"
  homepage "https://github.com/johnlindquist/claude-hooks"
  url "https://registry.npmjs.org/claude-hooks/-/claude-hooks-2.4.0.tgz"
  sha256 "b55f6dbdec8ec51f26f459bf2888ae9cd6deae1a1e3ac992904080e118b6e80b"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "92f9f476e0e0b76b139e09398b7e0fbb64010f1a25be3c265a0b807ba8fff011"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/claude-hooks --version")

    output = shell_output("#{bin}/claude-hooks init 2>&1", 1)
    assert_match "Claude Hooks Setup", output
  end
end
