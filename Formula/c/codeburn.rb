class Codeburn < Formula
  desc "See where your AI coding tokens go - by task, tool, model, and project"
  homepage "https://github.com/getagentseal/codeburn"
  url "https://registry.npmjs.org/codeburn/-/codeburn-0.9.22.tgz"
  sha256 "16856cd5b910eb16a632ac3c875f93118bf37c1106e55461ced5f7316f4c8498"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f2283a6cd8172c779df99a277ba4e4f55bee314c8c9524bc673c72c0183f6b75"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    output = shell_output("#{bin}/codeburn report --period today --format json")
    assert_match "\"generated\"", output
    assert_match "\"period\":", output
    assert_match "\"overview\"", output
  end
end
