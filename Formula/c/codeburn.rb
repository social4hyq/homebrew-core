class Codeburn < Formula
  desc "See where your AI coding tokens go - by task, tool, model, and project"
  homepage "https://github.com/getagentseal/codeburn"
  url "https://registry.npmjs.org/codeburn/-/codeburn-0.9.23.tgz"
  sha256 "1d7f3bd3e45af6bbe167e25468b5cfbf5a3d137139327a77564f39707e214a50"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "424e5dba0b72da6fe796f48bd096aa88f0577d2bd22c9b4e21dabbad09f66048"
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
