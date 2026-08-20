class Marked < Formula
  desc "Markdown parser and compiler built for speed"
  homepage "https://marked.js.org/"
  url "https://registry.npmjs.org/marked/-/marked-18.0.10.tgz"
  sha256 "546671792633e2770cc4b8e2a6037b5c523e8d18c5b6750c813281a9bb429ddf"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "133d49c638e187f80ab67289d19b9b3124bf2a54b37257ca03247d01f060d3ab"
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
