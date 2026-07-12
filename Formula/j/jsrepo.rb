class Jsrepo < Formula
  desc "Build and distribute your code"
  homepage "https://jsrepo.dev/"
  url "https://registry.npmjs.org/jsrepo/-/jsrepo-3.8.1.tgz"
  sha256 "bc1c7da93e84144f8b5644beefed26848083e1c023866848030ff811b12a0d3c"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e9fbb76325aca92f85b99c30c8b4fe2e096bd4c137cbef6738a451381c2859ed"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/jsrepo --version")

    (testpath/"package.json").write <<~JSON
      {
        "name": "test-package",
        "version": "1.0.0"
      }
    JSON
    system bin/"jsrepo", "init", "--yes"
  end
end
