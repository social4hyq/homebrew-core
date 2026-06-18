class Defuddle < Formula
  desc "Extract article content and metadata from web pages"
  homepage "https://github.com/kepano/defuddle"
  url "https://registry.npmjs.org/defuddle/-/defuddle-0.19.0.tgz"
  sha256 "d3120dfa4b04c168515b5c12e75492f5f68a5f52ff707175f0a0ca995853e055"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0a79d478ab5c48a776e9df7f8c699db0faa2b816334b36d970ccffcd93f00162"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/defuddle --version")

    (testpath/"test.html").write <<~HTML
      <html>
        <body>
          <article>
            <h1>Test Article</h1>
            <p>Hello from Homebrew.</p>
          </article>
        </body>
      </html>
    HTML
    assert_match "Hello from Homebrew.", shell_output("#{bin}/defuddle parse #{testpath}/test.html --md")
    assert_match "Test Article", shell_output("#{bin}/defuddle parse #{testpath}/test.html -p title")
  end
end
