class FaunaShell < Formula
  desc "Interactive shell for FaunaDB"
  homepage "https://fauna.com/"
  url "https://registry.npmjs.org/fauna-shell/-/fauna-shell-4.0.0.tgz"
  sha256 "6dd5c853c1a62e72d6101741a498b3b9fe4db21e68ec2e024541b488b858c77f"
  license "MPL-2.0"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7a9453bc6c77d4205a2bb1d0da62cc65c94cf12431ee7aa474848b8f4d4e9b67"
  end

  # Fauna Service Winding Down, https://news.ycombinator.com/item?id=43414742
  deprecate! date: "2025-06-22", because: :unmaintained
  disable! date: "2026-06-22", because: :unmaintained

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    # Remove incompatible pre-built binaries
    libexec.glob("lib/node_modules/fauna-shell/dist/{*.node,fauna}")
           .each { |f| rm(f) }
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/fauna --version")

    output = shell_output("#{bin}/fauna local --name local-fauna 2>&1", 1)
    assert_match "[StartContainer] Docker service is not available", output
  end
end
