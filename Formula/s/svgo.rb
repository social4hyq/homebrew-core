class Svgo < Formula
  desc "Nodejs-based tool for optimizing SVG vector graphics files"
  homepage "https://svgo.dev/"
  url "https://github.com/svg/svgo/archive/refs/tags/v4.0.2.tar.gz"
  sha256 "f83f6d0ab9c12b7773683b78c203c18e52aa7a8f3f0ea0cb59fbbacb4dbf21fa"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "202742f75726d7f9211c0f7dd3e12149bb12109c2412ac7666f80828b6cb42de"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    cp test_fixtures("test.svg"), testpath
    system bin/"svgo", "test.svg", "-o", "test.min.svg"
    assert_match(/^<svg /, (testpath/"test.min.svg").read)
  end
end
