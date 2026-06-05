class Shiki < Formula
  desc "Beautiful yet powerful syntax highlighter"
  homepage "https://shiki.style/"
  url "https://registry.npmjs.org/@shikijs/cli/-/cli-4.2.0.tgz"
  sha256 "c317df927be6d1efc20e6f6391b4ecaea999ad885404d5dbd9725f1f41ba8655"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "111032dc982b74e04da9d6bf8c09de74b731592be348adff6851916003da01f7"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/shiki --version")

    (testpath/"test.txt").write <<~TXT
      Hello, world!
    TXT

    assert_match "Hello, world!", shell_output("#{bin}/shiki #{testpath}/test.txt")
  end
end
