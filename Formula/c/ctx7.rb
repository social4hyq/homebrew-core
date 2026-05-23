class Ctx7 < Formula
  desc "Manage AI coding skills and documentation context"
  homepage "https://context7.com"
  url "https://registry.npmjs.org/ctx7/-/ctx7-0.4.4.tgz"
  sha256 "86ebadfeef7b85ba50ab2a1e0a16d3ef9b37e4fccd23d64d93eb0e2538ba9a9d"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2487a402373c5d51a2990ad43ad39d4c93abfb2c5e9518615ba2852b6e22efe9"
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
