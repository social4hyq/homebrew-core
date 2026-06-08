class Semver < Formula
  desc "Semantic version parser for node (the one npm uses)"
  homepage "https://github.com/npm/node-semver"
  url "https://github.com/npm/node-semver/archive/refs/tags/v7.8.3.tar.gz"
  sha256 "35bc00a54350b2c924796fb8d598541d7960882795d4391ef96bb07cd5c3e848"
  license "ISC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4f6b963eaf9014bf39cf0541841f1f6b0120d5cc2542e86a2bbe2d7e5446e8be"
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
