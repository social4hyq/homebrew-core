class Semver < Formula
  desc "Semantic version parser for node (the one npm uses)"
  homepage "https://github.com/npm/node-semver"
  url "https://github.com/npm/node-semver/archive/refs/tags/v7.8.1.tar.gz"
  sha256 "6ebe127bfe811ce7daf2c0107246672084e9ef2e001cf584a2272b7a583e0451"
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
