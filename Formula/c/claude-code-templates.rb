class ClaudeCodeTemplates < Formula
  desc "CLI tool for configuring and monitoring Claude Code"
  homepage "https://www.aitmpl.com/agents"
  url "https://registry.npmjs.org/claude-code-templates/-/claude-code-templates-1.29.4.tgz"
  sha256 "b5c67ea73eebb3bf6aee21556182d7aba4d58d12ac49acc5c98d351071a6babf"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d6d7f0132886eef06173da50d2c227a5674c8676a582582676103ee4db4281f2"
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
