class ClaudeCodeTemplates < Formula
  desc "CLI tool for configuring and monitoring Claude Code"
  homepage "https://www.aitmpl.com/agents"
  url "https://registry.npmjs.org/claude-code-templates/-/claude-code-templates-1.29.2.tgz"
  sha256 "ed0d89293d51b7adf19033fb8268b30722afa51a215524aa698890a28bc3055f"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4a1f7f3fbdfa1df72ebfbce7797fa1dde267c5109a84115c83210084535a3bf4"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args(ignore_scripts: false)
    bin.install_symlink libexec.glob("bin/*")

    # Remove pre-built binaries which were source-built via script
    rm_r libexec/"lib/node_modules/claude-code-templates/node_modules/bufferutil/prebuilds"
  end

  test do
    # TODO: recover version test in next release
    # assert_match version.to_s, shell_output("#{bin}/cct --version")

    output = shell_output("#{bin}/cct --command testing/generate-tests --yes")
    assert_match "Successfully installed 1 components", output
  end
end
