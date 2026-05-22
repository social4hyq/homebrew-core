class PatchPackage < Formula
  desc "Fix broken node modules instantly"
  homepage "https://github.com/ds300/patch-package"
  url "https://registry.npmjs.org/patch-package/-/patch-package-8.0.1.tgz"
  sha256 "fb36b47e1f22a3d612311bc9a0464b0213e0971958cfabb8f26a9537b1d7c4f7"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "41cb65c7ef504d116ce65065cb45c85cc7c4946c6f65feb25d8cb92dab0d5056"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    output = shell_output("#{bin}/patch-package 2>&1", 1)
    assert_match "no package.json found for this project", output

    (testpath/"package.json").write <<~JSON
      {
        "name": "brewtest",
        "version": "1.0.0"
      }
    JSON

    expected = <<~EOS
      patch-package #{version}
      Applying patches...
      No patch files found
    EOS
    assert_equal expected, shell_output("#{bin}/patch-package 2>&1")
  end
end
