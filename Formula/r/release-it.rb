class ReleaseIt < Formula
  desc "Generic CLI tool to automate versioning and package publishing related tasks"
  homepage "https://github.com/release-it/release-it"
  url "https://registry.npmjs.org/release-it/-/release-it-21.0.0.tgz"
  sha256 "1b307afe130be6b4e4db1c4aa5988764726f8640d6a40e1e28ac74189c27647e"
  license "MIT"

  livecheck do
    url :homepage
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "92c89c39092d0f967ff03cb3a45918754e1ff32fc795b0aaf26d84baa0e3a92e"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/release-it -v")
    (testpath/".release-it.json").write("{\"foo\": \"bar\"}")
    (testpath/"package.json").write("{\"name\":\"test-pkg\",\"version\":\"1.0.0\"}")
    assert_match(/Let's release test-pkg.+\(1\.0\.0\.\.\.1\.0\.1\).+Empty changelog.+Done \(in \d+s\.\)/m,
      shell_output("#{bin}/release-it --npm.skipChecks --no-npm.publish --ci"))
    assert_match "1.0.1", (testpath/"package.json").read
  end
end
