class Standard < Formula
  desc "JavaScript Style Guide, with linter & automatic code fixer"
  homepage "https://standardjs.com/"
  url "https://registry.npmjs.org/standard/-/standard-17.1.2.tgz"
  sha256 "fb2aaf22460bb3e77e090c727c694a56dd9a9486eec30a0152290a5c6d83757c"
  license "MIT"
  head "https://github.com/standard/standard.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "40dbd99ccb6350245e2a0948050c043c36e36985b31d6a364a3689c2b061fd58"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/"foo.js").write <<~JS
      console.log("hello there")
      if (name != 'John') { }
    JS
    output = shell_output("#{bin}/standard foo.js 2>&1", 1)
    assert_match "Strings must use singlequote. (quotes)", output
    assert_match "Expected '!==' and instead saw '!='. (eqeqeq)", output
    assert_match "Empty block statement. (no-empty)", output

    assert_match version.to_s, shell_output("#{bin}/standard --version")
  end
end
