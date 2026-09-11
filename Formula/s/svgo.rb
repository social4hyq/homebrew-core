class Svgo < Formula
  desc "Nodejs-based tool for optimizing SVG vector graphics files"
  homepage "https://svgo.dev/"
  url "https://github.com/svg/svgo/archive/refs/tags/v4.1.0.tar.gz"
  sha256 "8c9d43624e108eab29e369fdca68ea160e57b37a364907b499b5d6a4436cb59b"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dfffec20068c3243629151536fd5a9d391eabf5f6ae6f76e9985de2acdc25db6"
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
