class Ctx7 < Formula
  desc "Manage AI coding skills and documentation context"
  homepage "https://context7.com"
  url "https://registry.npmjs.org/ctx7/-/ctx7-0.5.5.tgz"
  sha256 "5982a3845936b49ed7f32a21f97efad06ae22a85fc0be71a7c8b8fa503649c18"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "67332b8732b595793efb28db237357f1ee2ed1158deb851d728d76072a50420f"
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
