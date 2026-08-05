class Oxfmt < Formula
  desc "High-performance formatting tool for JavaScript and TypeScript"
  homepage "https://oxc.rs/"
  url "https://registry.npmjs.org/oxfmt/-/oxfmt-0.62.0.tgz"
  sha256 "d587ed382f26084bd6e001eeb07ee4043dce54a4829c924495c522689144d354"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cc507de0c93c6d2227528a5b1feae3e7704af589e23909c708d9718c65a832ef"
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
