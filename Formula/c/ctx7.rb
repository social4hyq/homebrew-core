class Ctx7 < Formula
  desc "Manage AI coding skills and documentation context"
  homepage "https://context7.com"
  url "https://registry.npmjs.org/ctx7/-/ctx7-0.5.0.tgz"
  sha256 "3cd8926e7fa40689d34e667776a4733e16b7ca694364c2d1e02e9e91732d3324"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "910c0370e7424f0a11d5bb6d9c1a3859679657aba97b5e96ac058b778b26a0b4"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ctx7 --version")
    assert_match "Not logged in", shell_output("#{bin}/ctx7 whoami")
    assert_match "No skills installed", shell_output("#{bin}/ctx7 skills list")
    system bin/"ctx7", "library", "react", "hooks"
  end
end
