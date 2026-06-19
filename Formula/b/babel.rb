class Babel < Formula
  desc "Compiler for writing next generation JavaScript"
  homepage "https://babeljs.io/"
  url "https://registry.npmjs.org/@babel/cli/-/cli-8.0.1.tgz"
  sha256 "5cc94939d72c31145a4a14b20c4e6d51af94d26e4e49d95137a661fe60725cda"
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
