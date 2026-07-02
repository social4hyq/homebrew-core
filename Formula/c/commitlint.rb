class Commitlint < Formula
  desc "Lint commit messages according to a commit convention"
  homepage "https://commitlint.js.org/#/"
  url "https://registry.npmjs.org/commitlint/-/commitlint-21.2.0.tgz"
  sha256 "34994c75fd55daae81acf554acf1506c9d05b3427a7c47bfa242f333ebcc6365"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "783672ea0d6e1ca287eba07371f7aeb6c41604a171776ed4d0cfc36a867a7e08"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    # Remove comment to build :all bottle
    node_modules = libexec/"lib/node_modules/commitlint/node_modules"
    inreplace node_modules/"global-directory/index.js", "/opt/homebrew", "HOMEBREW_PREFIX"
  end

  test do
    (testpath/"commitlint.config.js").write <<~JS
      module.exports = {
          rules: {
            'type-enum': [2, 'always', ['foo']],
          },
        };
    JS
    assert_match version.to_s, shell_output("#{bin}/commitlint --version")
    assert_empty pipe_output(bin/"commitlint", "foo: message")
  end
end
