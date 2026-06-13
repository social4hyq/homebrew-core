class NodeSass < Formula
  desc "JavaScript implementation of a Sass compiler"
  homepage "https://github.com/sass/dart-sass"
  url "https://registry.npmjs.org/sass/-/sass-1.101.0.tgz"
  sha256 "37c6d52073f164c05c8d5276df8b377642a472193b8d54dfad5c296ab4623abc"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aa43ded3c302475b84e64dedaed0d79f3efbf6f10296d2148b871be004cbb0cb"
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
