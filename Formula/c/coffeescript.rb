class Coffeescript < Formula
  desc "Unfancy JavaScript"
  homepage "https://coffeescript.org/"
  url "https://registry.npmjs.org/coffeescript/-/coffeescript-2.7.0.tgz"
  sha256 "590e2036bd24d3b54e598b56df2e0737a82c2aa966c1020338508035f3b4721f"
  license "MIT"
  head "https://github.com/jashkenas/coffeescript.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1923d7b4ee36926e47289d3bca2d5c36a4122869003f02b92fc1426cdc14ded3"
  end

  depends_on "node"

  conflicts_with "cake", because: "both install `cake` binaries"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/"test.coffee").write <<~EOS
      square = (x) -> x * x
      list = [1, 2, 3, 4, 5]

      math =
        root:   Math.sqrt
        square: square
        cube:   (x) -> x * square x

      cubes = (math.cube num for num in list)
    EOS

    system bin/"coffee", "--compile", "test.coffee"
    assert_path_exists testpath/"test.js", "test.js was not generated"
  end
end
