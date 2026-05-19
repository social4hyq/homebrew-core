class Autocode < Formula
  desc "Code automation for every language, library and framework"
  homepage "https://autocode.readme.io/"
  url "https://registry.npmjs.org/autocode/-/autocode-1.3.1.tgz"
  sha256 "952364766e645d4ddae30f9d6cc106fdb74d05afc4028066f75eeeb17c4b0247"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "28a073574269fc43d9468b182d89f8d500b46fcdbd5a762a0d7d695cd8bc4a57"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/".autocode/config.yml").write <<~YAML
      name: test
      version: 0.1.0
      description: test description
      author:
        name: Test User
        email: test@example.com
        url: https://example.com
      copyright: 2015 Test
    YAML
    system bin/"autocode", "build"
  end
end
