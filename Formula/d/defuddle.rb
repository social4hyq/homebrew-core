class Defuddle < Formula
  desc "Extract article content and metadata from web pages"
  homepage "https://github.com/kepano/defuddle"
  url "https://registry.npmjs.org/defuddle/-/defuddle-0.19.3.tgz"
  sha256 "5ee0e894b27f8342975f7acbbb96dd31b79baa0e2f1bba47d0d25f16cc49d153"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f758c0731ac9b2a2ddb4d85bf72e2fd547982324e2523fac85bfe4dca043e258"
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
