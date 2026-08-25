class ContentfulCli < Formula
  desc "Contentful command-line tools"
  homepage "https://github.com/contentful/contentful-cli"
  url "https://registry.npmjs.org/contentful-cli/-/contentful-cli-4.0.9.tgz"
  sha256 "1cbaa08ff448e851b42de1602d63b6fad7c6a3868ca057689371cdcf50b1c059"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "daf69060bd3f44658dc10f593f1a76d2c0118db772ea1c0eeb9e2586e1d1e76b"
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
