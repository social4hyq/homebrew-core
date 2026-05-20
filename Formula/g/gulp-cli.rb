class GulpCli < Formula
  desc "Command-line utility for Gulp"
  homepage "https://github.com/gulpjs/gulp-cli"
  url "https://registry.npmjs.org/gulp-cli/-/gulp-cli-3.1.0.tgz"
  sha256 "683fa88d8d15b49a8adf760f25e4e46f068f1e065fe234e1199b27fe6bf0376e"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e0fe5eaa5cf4af917f2be685254fb0378709316c664d75d55eef1676627de5ae"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    system "npm", "init", "-y"
    system "npm", "install", *std_npm_args(prefix: false), "gulp"

    output = shell_output("#{bin}/gulp --version")
    assert_match "CLI version: #{version}", output
    assert_match "Local version: ", output

    (testpath/"gulpfile.js").write <<~JS
      function defaultTask(cb) {
        cb();
      }
      exports.default = defaultTask
    JS
    assert_match "Finished 'default' after ", shell_output("#{bin}/gulp")
  end
end
