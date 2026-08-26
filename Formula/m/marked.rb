class Marked < Formula
  desc "Markdown parser and compiler built for speed"
  homepage "https://marked.js.org/"
  url "https://registry.npmjs.org/marked/-/marked-18.0.11.tgz"
  sha256 "cef55476c7551e73e1a89118fa69fee9f7eef9960e9c774ad266e22ee966b994"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "279bfd3ff9d4122d5b5b33da8b5431cda021b2071d48f51a00d41d4e8baf8c17"
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
