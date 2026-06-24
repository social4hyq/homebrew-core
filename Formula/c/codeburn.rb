class Codeburn < Formula
  desc "See where your AI coding tokens go - by task, tool, model, and project"
  homepage "https://github.com/getagentseal/codeburn"
  url "https://registry.npmjs.org/codeburn/-/codeburn-0.9.14.tgz"
  sha256 "690a83e0a19bec4c5440858c66e4e6880f289d6905bc7fd18617bffa4bd4bced"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a226106df965888e74227823a4975754e5add68fa162452e0f43fc7a47fbe6eb"
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
