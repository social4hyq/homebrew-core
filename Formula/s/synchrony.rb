class Synchrony < Formula
  desc "Simple deobfuscator for mangled or obfuscated JavaScript files"
  homepage "https://deobfuscate.relative.im/"
  url "https://registry.npmjs.org/deobfuscator/-/deobfuscator-2.4.5.tgz"
  sha256 "feca0c36e1efe029827f2cb44d206c9e32751f207dae25ca5a93a4e6fe21388d"
  license "GPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "03154c247f4e7ee00603f56610d7d665a8d01870d7d62e9f695f322d44791816"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    resource "test-file" do
      url "https://gist.github.com/relative/79e392bced4b9bed8fd076f834e06dee/raw/obfuscated.js"
      sha256 "01058a548c9beb1df0586ddb30ca88256b15dba4bd5b95ddf90541dbaceef0b0"
    end

    testpath.install resource("test-file")
    system bin/"synchrony", "deobfuscate", "obfuscated.js"
    assert_match "console.log('test message');", (testpath/"obfuscated.cleaned.js").read

    assert_match version.to_s, shell_output("#{bin}/synchrony --version")
  end
end
