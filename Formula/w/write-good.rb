class WriteGood < Formula
  desc "Naive linter for English prose"
  homepage "https://github.com/btford/write-good"
  url "https://registry.npmjs.org/write-good/-/write-good-1.0.8.tgz"
  sha256 "f54db3db8db0076fd1c05411c7f3923f055176632c51dc4046ab216e51130221"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "24276c0b6355f38e2720895c885b542de74e416276391ce959144f27c443125f"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/"test.txt").write "So the cat was stolen."
    assert_match "passive voice", shell_output("#{bin}/write-good test.txt", 2)
  end
end
