class Babel < Formula
  desc "Compiler for writing next generation JavaScript"
  homepage "https://babeljs.io/"
  url "https://registry.npmjs.org/@babel/cli/-/cli-8.0.5.tgz"
  sha256 "210ed579cf6d37c0ac93df78c6fd52fee67f392485a92ac7b42ff38cc3030751"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "984b1839ab4a35a628658a98a2c73b61aa29957d6ae87d38beb3d7e5bf2e5764"
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
