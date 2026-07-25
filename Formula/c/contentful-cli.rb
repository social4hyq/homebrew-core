class ContentfulCli < Formula
  desc "Contentful command-line tools"
  homepage "https://github.com/contentful/contentful-cli"
  url "https://registry.npmjs.org/contentful-cli/-/contentful-cli-4.0.5.tgz"
  sha256 "8b796443c0c0afcc3db5d47689ab955bddcab0f1058ef9864f2ea1745582de09"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "927e2ff7fa34b117ee394b866aaca02fbe3b3100b6cc4185725afbf25a512960"
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
