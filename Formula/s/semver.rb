class Semver < Formula
  desc "Semantic version parser for node (the one npm uses)"
  homepage "https://github.com/npm/node-semver"
  url "https://github.com/npm/node-semver/archive/refs/tags/v7.8.0.tar.gz"
  sha256 "bc2abf58261499a56264e21c456c0c23805e91c2da502d3957e9de96f4d33cc3"
  license "ISC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a5f2e20104941ea42cc3b57f22e7d8a4191c303b0840e3cbeef50681fc28a963"
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
