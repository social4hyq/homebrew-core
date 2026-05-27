class Eleventy < Formula
  desc "Simpler static site generator"
  homepage "https://www.11ty.dev"
  url "https://registry.npmjs.org/@11ty/eleventy/-/eleventy-3.1.5.tgz"
  sha256 "65941649a92338aad8021fc0d0df1954b632f31299579f3e0ac72ef2a20a70d4"
  license "MIT"
  head "https://github.com/11ty/eleventy.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1bb28f2a5f8ff6e3310cb5fead3406d7acc8c479bfc2a70c7d7d6794b6ec9fe3"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    deuniversalize_machos libexec/"lib/node_modules/@11ty/eleventy/node_modules/fsevents/fsevents.node" if OS.mac?
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/"README.md").write "# Hello from Homebrew\nThis is a test."
    system bin/"eleventy"
    assert_equal "<h1>Hello from Homebrew</h1>\n<p>This is a test.</p>\n",
                 (testpath/"_site/README/index.html").read
  end
end
