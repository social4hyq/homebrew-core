class Marked < Formula
  desc "Markdown parser and compiler built for speed"
  homepage "https://marked.js.org/"
  url "https://registry.npmjs.org/marked/-/marked-18.0.4.tgz"
  sha256 "59709b558d874245d39ab7c64a72c8cce5924a0279d7cad82cae56463e09419b"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "89e0cfee63f203ecf27be65f3f95e8d5a31f01eb1f4aef0e7b0607f42ee51531"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_equal "<p>hello <em>world</em></p>", shell_output("#{bin}/marked -s 'hello *world*'").strip
  end
end
