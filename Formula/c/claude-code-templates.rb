class ClaudeCodeTemplates < Formula
  desc "CLI tool for configuring and monitoring Claude Code"
  homepage "https://www.aitmpl.com/agents"
  url "https://registry.npmjs.org/claude-code-templates/-/claude-code-templates-1.29.6.tgz"
  sha256 "7928da3e3140ef1d7422aeea87fde4d0fdc74d89d47ceef235fdeba299e3f926"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ea8b7f1d23b0d1c78cb210b9f06aa5421e62bd5e14ff844260d7b7b7accddd6e"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args(ignore_scripts: false)
    bin.install_symlink libexec.glob("bin/*")

    # Remove pre-built binaries which were source-built via script.
    # "bufferutil" is an optional peer dependency of "ws" and is no longer
    # installed since 1.29.6, so only remove the prebuilds when it exists.
    prebuilds = libexec/"lib/node_modules/claude-code-templates/node_modules/bufferutil/prebuilds"
    rm_r(prebuilds) if prebuilds.exist?
  end

  test do
    # TODO: recover version test in next release
    # assert_match version.to_s, shell_output("#{bin}/cct --version")

    output = shell_output("#{bin}/cct --command testing/generate-tests --yes")
    assert_match "Successfully installed 1 components", output
  end
end
