class Pyright < Formula
  desc "Static type checker for Python"
  homepage "https://github.com/microsoft/pyright"
  url "https://registry.npmjs.org/pyright/-/pyright-1.1.414.tgz"
  sha256 "bf5f473f6167c0d14175492c3263d783b4489a6956e1c06c18e15228e3a3fa42"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "69ce25cbd5e897b79f8aa5a8e8639d959bc3bb531264921e011659f02ffbc682"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args(ignore_scripts: false)
    bin.install_symlink libexec.glob("bin/*")

    # Remove empty directory to make all bottle
    rm_r libexec/"lib/node_modules/pyright/node_modules" if OS.mac?
  end

  test do
    (testpath/"broken.py").write <<~PYTHON
      def wrong_types(a: int, b: int) -> str:
          return a + b
    PYTHON
    output = pipe_output("#{bin}/pyright broken.py 2>&1")
    assert_match "error: Type \"int\" is not assignable to return type \"str\"", output
  end
end
