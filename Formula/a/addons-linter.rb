class AddonsLinter < Formula
  desc "Firefox Add-ons linter, written in JavaScript"
  homepage "https://github.com/mozilla/addons-linter"
  url "https://registry.npmjs.org/addons-linter/-/addons-linter-10.5.0.tgz"
  sha256 "7526bba496af8a0e02d87991b704159191713b1c02e87da0aa2ff5bbd63cb444"
  license "MPL-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "539fcfdf814309f915c44da0da7983cff885643931b3059588586e39eead8bfb"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/addons-linter --version")

    (testpath/"manifest.json").write <<~JSON
      {
        "manifest_version": 2,
        "name": "Test Addon",
        "version": "1.0",
        "description": "A test addon",
        "applications": {
          "gecko": {
            "id": "test-addon@example.com"
          }
        }
      }
    JSON
    output = shell_output("#{bin}/addons-linter #{testpath}/manifest.json 2>&1")
    assert_match "BAD_ZIPFILE   Corrupt ZIP", output
  end
end
