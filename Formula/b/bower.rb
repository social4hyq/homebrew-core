class Bower < Formula
  desc "Package manager for the web"
  homepage "https://bower.io/"
  url "https://registry.npmjs.org/bower/-/bower-1.8.14.tgz"
  sha256 "00df3dcc6e8b3a4dd7668934a20e60e6fc0c4269790192179388c928553a3f7e"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a2f303198a837eb039b3815433624a133d61dac55373b98c1981a7bad42867b3"
  end

  depends_on "node"

  conflicts_with "bower-mail", because: "both install `bower` binaries"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    system bin/"bower", "install", "jquery"
    assert_path_exists testpath/"bower_components/jquery/dist/jquery.min.js", "jquery.min.js was not installed"
  end
end
