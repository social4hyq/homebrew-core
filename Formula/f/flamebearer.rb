class Flamebearer < Formula
  desc "Blazing fast flame graph tool for V8 and Node"
  homepage "https://github.com/mapbox/flamebearer"
  url "https://registry.npmjs.org/flamebearer/-/flamebearer-1.1.3.tgz"
  sha256 "e787b71204f546f79360fd103197bc7b68fb07dbe2de3a3632a3923428e2f5f1"
  license "ISC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dd2ebb1b13e472092f1c8cfebdd069ee87e1478a5becf24d72da1fec6634da3f"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/"app.js").write "console.log('hello');"
    system Formula["node"].bin/"node", "--prof", testpath/"app.js"
    logs = testpath.glob("isolate*.log")

    assert_match "Processed V8 log",
      pipe_output(
        bin/"flamebearer",
        shell_output("#{Formula["node"].bin}/node --prof-process --preprocess -j #{logs.join(" ")}"),
      )

    assert_path_exists testpath/"flamegraph.html"
  end
end
