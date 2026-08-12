class Shiki < Formula
  desc "Beautiful yet powerful syntax highlighter"
  homepage "https://shiki.style/"
  url "https://registry.npmjs.org/@shikijs/cli/-/cli-4.4.3.tgz"
  sha256 "26ba2accb28a6d226359757611540171fcacdd48bfac1eee67cdbd6d8fbef776"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "01a7a7611b02473bb219872d599d1d69b007173ea13b6ca939c7516ee4443938"
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
