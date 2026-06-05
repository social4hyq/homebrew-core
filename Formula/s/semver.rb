class Semver < Formula
  desc "Semantic version parser for node (the one npm uses)"
  homepage "https://github.com/npm/node-semver"
  url "https://github.com/npm/node-semver/archive/refs/tags/v7.8.2.tar.gz"
  sha256 "4a176d6648ce90228a8dfe784c9142d9671f0a6d05a1865550028b59629d5c03"
  license "ISC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3e26961a52c2dfa1e08b79d77da01a43ebd20e1e8839eb734a2dc7eb0004bfa4"
  end
  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/semver --help")
    assert_match "1.2.3", shell_output("#{bin}/semver 1.2.3-beta.1 -i release")
  end
end
