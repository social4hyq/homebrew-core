class Babel < Formula
  desc "Compiler for writing next generation JavaScript"
  homepage "https://babeljs.io/"
  url "https://registry.npmjs.org/@babel/cli/-/cli-8.0.0.tgz"
  sha256 "aa9a8ed43f3092864cc21b53f569061d4159910e742c6cd51c40e7b5b1f924fe"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "71c952e284319c5cdad74d56478dd70db443cc580596b42b5de7d9533382bf9b"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    node_modules = libexec/"lib/node_modules/@babel/cli/node_modules"
    deuniversalize_machos node_modules/"fsevents/fsevents.node" if OS.mac?
  end

  test do
    (testpath/"script.js").write <<~JS
      [1,2,3].map(n => n + 1);
    JS

    system bin/"babel", "script.js", "--out-file", "script-compiled.js"
    assert_path_exists testpath/"script-compiled.js", "script-compiled.js was not generated"
  end
end
