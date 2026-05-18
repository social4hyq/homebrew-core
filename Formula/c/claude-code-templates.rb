class ClaudeCodeTemplates < Formula
  desc "CLI tool for configuring and monitoring Claude Code"
  homepage "https://www.aitmpl.com/agents"
  url "https://registry.npmjs.org/claude-code-templates/-/claude-code-templates-1.28.16.tgz"
  sha256 "1e451ce1049ecf5beed9a0f023d51997c7bd0f9868e85b1dfddb9a5b875d8cbd"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4a1f7f3fbdfa1df72ebfbce7797fa1dde267c5109a84115c83210084535a3bf4"
  end

  depends_on "node"

  # Backport cli-tool version metadata fix.
  patch do
    url "https://github.com/davila7/claude-code-templates/commit/55b8c382abc412180f2c30c07644c5b2b5d01892.patch?full_index=1"
    sha256 "30cc5661d33eb67dbf1981012c9df873b52006c3929ae9fdd37d1c6b0955c16f"
  end

  def install
    system "npm", "install", *std_npm_args(ignore_scripts: false)
    bin.install_symlink libexec.glob("bin/*")

    os = OS.kernel_name.downcase
    arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s
    # Remove incompatible pre-built binaries.
    libexec.glob("lib/node_modules/claude-code-templates/node_modules/{bufferutil}/prebuilds/*").each do |dir|
      rm_r(dir) if dir.basename.to_s != "#{os}-#{arch}"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cct --version")

    output = shell_output("#{bin}/cct --command testing/generate-tests --yes")
    assert_match "Successfully installed 1 components", output
  end
end
