class NodeSass < Formula
  desc "JavaScript implementation of a Sass compiler"
  homepage "https://github.com/sass/dart-sass"
  url "https://registry.npmjs.org/sass/-/sass-1.103.0.tgz"
  sha256 "aa41b084177163ccd87a524ce810bee0e3e26b2d87980f3f0c489d9c3e7ed3b3"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "58f587fcf9be626d9dfeb1356f8a110b8db65a4822200b51c8d11de8c235da5f"
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
