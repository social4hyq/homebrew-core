class Babel < Formula
  desc "Compiler for writing next generation JavaScript"
  homepage "https://babeljs.io/"
  url "https://registry.npmjs.org/@babel/cli/-/cli-7.29.7.tgz"
  sha256 "7620855acd400b22c1972c23a5a60a9d3340c52b059df7f26ebaa50316d9f49d"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6949a412ff0330bcc79514cd5cb280b8e64e32d163b52d51f8995da1148c9334"
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
