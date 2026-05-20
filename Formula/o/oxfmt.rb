class Oxfmt < Formula
  desc "High-performance formatting tool for JavaScript and TypeScript"
  homepage "https://oxc.rs/"
  url "https://registry.npmjs.org/oxfmt/-/oxfmt-0.51.0.tgz"
  sha256 "944c640c2b7e9edae82a378c49c1315331bb736e84fb92a1dad76463c9b09e63"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8203c2dacfb5ca19c9aed20caf97d574c1200a5e760a03da1df68569633e00c2"
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
