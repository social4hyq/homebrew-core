class Yo < Formula
  desc "CLI tool for running Yeoman generators"
  homepage "https://yeoman.io"
  url "https://registry.npmjs.org/yo/-/yo-7.0.1.tgz"
  sha256 "466f653547a99ae4cf0de84beac13b8a882804f56718d81df3a2327343bbf7f4"
  license "BSD-2-Clause"
  revision 1
  head "https://github.com/yeoman/yo.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6eabb276d2dbf794eb6121faee668a2602d242b6d6b4f9b835c8e28a37ffad49"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/yo --version")
    assert_match "Couldn't find any generators", shell_output("#{bin}/yo --generators")
    assert_match "Running sanity checks on your system", shell_output("#{bin}/yo doctor")
  end
end
