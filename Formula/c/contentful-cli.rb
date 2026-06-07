class ContentfulCli < Formula
  desc "Contentful command-line tools"
  homepage "https://github.com/contentful/contentful-cli"
  url "https://registry.npmjs.org/contentful-cli/-/contentful-cli-4.0.2.tgz"
  sha256 "8763c9bf7c45cbf953fd6be40309d9eef09034f1e2c960000ffa4401e74bd307"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9e3a89da0a1f14d0780eab0d26c3f6fccacb9ff18484ed73b7e81030e0a6b72a"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    output = shell_output("#{bin}/contentful space list 2>&1", 1)
    assert_match "🚨  Error: You have to be logged in to do this.", output
    assert_match "You can log in via contentful login", output
    assert_match "Or provide a management token via --management-token argument", output
  end
end
