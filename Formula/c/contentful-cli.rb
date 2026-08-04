class ContentfulCli < Formula
  desc "Contentful command-line tools"
  homepage "https://github.com/contentful/contentful-cli"
  url "https://registry.npmjs.org/contentful-cli/-/contentful-cli-4.0.6.tgz"
  sha256 "8762ee522cbf9a6aa1812b8ceba0e55cea643b81f5f2bcc83d25f66acdbe6b56"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c18eaf98945eb4b2820b19989979b2744470af4314790d41f76df40cc3ab6f79"
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
