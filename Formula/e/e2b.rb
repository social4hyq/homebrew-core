class E2b < Formula
  desc "CLI to manage E2B sandboxes and templates"
  homepage "https://e2b.dev"
  url "https://registry.npmjs.org/@e2b/cli/-/cli-2.10.4.tgz"
  sha256 "52b132e36ff54139be2f4fd6db2d31810da0f7836e47e48905e7211099aea0c7"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3e651899d0e2a513ceb4979cab6e45003836cb52e7965daec0bfe8a3b6a417d7"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/e2b --version")
    assert_match "Not logged in", shell_output("#{bin}/e2b auth info")
  end
end
