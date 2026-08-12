class Codeburn < Formula
  desc "See where your AI coding tokens go - by task, tool, model, and project"
  homepage "https://github.com/getagentseal/codeburn"
  url "https://registry.npmjs.org/codeburn/-/codeburn-0.9.20.tgz"
  sha256 "4416d3b074047dba22b909a34347dd0d388d06679c7ca6e4d2d98420bef21d1c"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5dd791b30acd9a46fe5535494401c38c366f85bfec8effbda05e3078bb9bfb28"
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
