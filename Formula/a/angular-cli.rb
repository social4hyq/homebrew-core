class AngularCli < Formula
  desc "CLI tool for Angular"
  homepage "https://angular.dev/cli/"
  url "https://registry.npmjs.org/@angular/cli/-/cli-22.0.5.tgz"
  sha256 "580d0777edf1ec46ebdecb4c0f59f6cfda571141f2936a803e22fdfd8d72f7be"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "746d1185913a0b0ffe7649b374864f64dc5840e51a1dac00f392b2c4999cdda6"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    system bin/"ng", "new", "angular-homebrew-test", "--skip-install"
    assert_path_exists testpath/"angular-homebrew-test/package.json", "Project was not created"
  end
end
