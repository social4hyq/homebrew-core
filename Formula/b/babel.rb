class Babel < Formula
  desc "Compiler for writing next generation JavaScript"
  homepage "https://babeljs.io/"
  url "https://registry.npmjs.org/@babel/cli/-/cli-8.0.4.tgz"
  sha256 "22e81b0f1a3d3886f86154857810200efe2536a57065b1222c07eeb1967fbc81"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "208ce38d52eb4b304a37d18dda6fc9f25387c1223ecdbbdb6cd48e3de8a24248"
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
