class Defuddle < Formula
  desc "Extract article content and metadata from web pages"
  homepage "https://github.com/kepano/defuddle"
  url "https://registry.npmjs.org/defuddle/-/defuddle-0.19.2.tgz"
  sha256 "a97f05a2cb115454669200b97a11db8b515382887d23c6360330edf67de64591"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "22af3f803bde4c0666cd56a030eb08029a338b3c1ec7364da81473c7dc743630"
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
