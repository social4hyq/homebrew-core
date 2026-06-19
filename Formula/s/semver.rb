class Semver < Formula
  desc "Semantic version parser for node (the one npm uses)"
  homepage "https://github.com/npm/node-semver"
  url "https://github.com/npm/node-semver/archive/refs/tags/v7.8.5.tar.gz"
  sha256 "0e31552648ead32c3d56f0df70db8db9e4f979720be7b6929aa98a98bd36529f"
  license "ISC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b17d3526d0f082a02d314b82a67a626a06b8c91cb4d359908326e977ff9109b0"
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
