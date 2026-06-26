class Commitlint < Formula
  desc "Lint commit messages according to a commit convention"
  homepage "https://commitlint.js.org/#/"
  url "https://registry.npmjs.org/commitlint/-/commitlint-21.1.0.tgz"
  sha256 "ee18109f0fc8dd162d5cadf7f0a00fa02caffbf7f023576a3dd111fc34169da9"
  license "MIT"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0707c09cc939c43022e6e5dc3b52002a83658a2df7bb245d09767d81b9a90fdb"
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
