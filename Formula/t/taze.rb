class Taze < Formula
  desc "Modern cli tool that keeps your deps fresh"
  homepage "https://github.com/antfu-collective/taze"
  url "https://registry.npmjs.org/taze/-/taze-19.17.1.tgz"
  sha256 "02aa4067d6a5c6cf42a35b484cffe4e58a2d253a33ef93cd914a9eb2eff66d61"
  license "MIT"
  head "https://github.com/antfu-collective/taze.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fd1af07aa83a252e0bb5b35df44012a3e9127cf160ce0c1b20c2f721f6d3fbad"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/taze --version")

    (testpath/"package.json").write <<~JSON
      {
        "name": "brewtest",
        "version": "1.0.0",
        "dependencies": {
          "homebrew-nonexistent": "1.1.0"
        }
      }
    JSON

    output = shell_output("#{bin}/taze 2>&1")
    assert_match "Failed to fetch package \"homebrew-nonexistent\"", output
  end
end
