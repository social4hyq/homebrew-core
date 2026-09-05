class Oxfmt < Formula
  desc "High-performance formatting tool for JavaScript and TypeScript"
  homepage "https://oxc.rs/"
  url "https://registry.npmjs.org/oxfmt/-/oxfmt-0.66.0.tgz"
  sha256 "f42e9c2d895c7b3c383c9fb1a510840436d334e69c5b4e9ec669fc92a0770f52"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "abcf635154dd3563ce0bf78ba1758dfb7fed07c93b8656ee5f3098e362dd590d"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/"test.js").write("const arr = [1,2];")
    system bin/"oxfmt", "test.js"
    assert_equal "const arr = [1, 2];\n", (testpath/"test.js").read
  end
end
