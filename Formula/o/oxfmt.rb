class Oxfmt < Formula
  desc "High-performance formatting tool for JavaScript and TypeScript"
  homepage "https://oxc.rs/"
  url "https://registry.npmjs.org/oxfmt/-/oxfmt-0.57.0.tgz"
  sha256 "4868919a9570cb5bf68ac1f7205011ff2daa23bb37f870fe6d433ba00b01cd98"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "162799fca298a51a238a6948a2ed7124521f74bded0d78bf308d8ad5b9f7ce7f"
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
