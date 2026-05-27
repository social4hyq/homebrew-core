class NodeSass < Formula
  desc "JavaScript implementation of a Sass compiler"
  homepage "https://github.com/sass/dart-sass"
  url "https://registry.npmjs.org/sass/-/sass-1.100.0.tgz"
  sha256 "21c392fda32899b07c59a5e132f2503b72429ae47600bf205420e981214a4af9"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "02a1d7cb9bc85bfb7d43e675c2a2c52cdb5a540a65458ae32ccdf3ad343c5b3c"
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
