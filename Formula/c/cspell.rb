class Cspell < Formula
  desc "Spell checker for code"
  homepage "https://cspell.org"
  url "https://registry.npmjs.org/cspell/-/cspell-10.1.1.tgz"
  sha256 "27ce78b60604e4efd46fdb88b7efe136870c8bc62caf61b3a0a29adf9fc25b41"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "363873bfde11eb653e0e77f53c3b1d81eb397e100507b99d84af6426726f8397"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    # Skip linking cspell-esm binary, which is identical to cspell.
    bin.install_symlink libexec/"bin/cspell"

    # Replace code comment to build :all bottle
    node_modules = libexec/"lib/node_modules/cspell/node_modules"
    inreplace node_modules/"global-directory/index.js", "/opt/homebrew", ""
  end

  test do
    (testpath/"test.rb").write("misspell_worrd = 1")
    output = shell_output("#{bin}/cspell test.rb", 1)
    assert_match "test.rb:1:10 - Unknown word (worrd)", output
  end
end
