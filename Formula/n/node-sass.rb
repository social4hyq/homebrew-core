class NodeSass < Formula
  desc "JavaScript implementation of a Sass compiler"
  homepage "https://github.com/sass/dart-sass"
  url "https://registry.npmjs.org/sass/-/sass-1.104.0.tgz"
  sha256 "38d27c532071b573b75498ca7ef61738d769f40a8ad6f8564cca28334473bba7"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "defcebd027cbc3aafbea6e46d74665ff919ab9091ba204c90560683e76bcc37e"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/"test.scss").write <<~EOS
      div {
        img {
          border: 0px;
        }
      }
    EOS

    assert_equal "div img{border:0px}",
    shell_output("#{bin}/sass --style=compressed test.scss").strip
  end
end
