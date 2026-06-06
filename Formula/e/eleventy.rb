class Eleventy < Formula
  desc "Simpler static site generator"
  homepage "https://www.11ty.dev"
  url "https://registry.npmjs.org/@11ty/eleventy/-/eleventy-3.1.6.tgz"
  sha256 "326f9e03a76665722c723be64e1021353143f6941fe1f53dd9d700405fd539a3"
  license "MIT"
  head "https://github.com/11ty/eleventy.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dea0aa153bf234347598b148319196aa5305cec1465a5a3f42750f7670b79079"
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
