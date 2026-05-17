class ContentfulCli < Formula
  desc "Contentful command-line tools"
  homepage "https://github.com/contentful/contentful-cli"
  url "https://registry.npmjs.org/contentful-cli/-/contentful-cli-4.0.1.tgz"
  sha256 "465e6fdb2cef5c2f9e53b7601ef7c58786c1a2e81ee7de851bbbcec7687b3d82"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fe0eddb8e56d088b0da2eb90a9479438303244a7b57205797f0407b6186032da"
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
