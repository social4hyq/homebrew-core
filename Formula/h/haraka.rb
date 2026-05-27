class Haraka < Formula
  desc "Fast, highly extensible, and event driven SMTP server"
  homepage "https://haraka.github.io/"
  url "https://registry.npmjs.org/Haraka/-/Haraka-3.2.1.tgz"
  sha256 "0353c12bfb8fbf541bab42c15ca7111c067bf43a8a47ff9772d0c98fa420cd88"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "88835113d90acb036b2d4c71c42c17b66d0dd67a1165d822344084a30b6753f0"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/haraka --version")

    system bin/"haraka", "--install", testpath/"config"
    assert_path_exists testpath/"config/README"

    output = shell_output("#{bin}/haraka --list")
    assert_match "plugins/auth", output
  end
end
