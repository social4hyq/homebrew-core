class ImmichCli < Formula
  desc "Command-line interface for self-hosted photo manager Immich"
  homepage "https://immich.app/docs/features/command-line-interface"
  url "https://registry.npmjs.org/@immich/cli/-/cli-3.2.2.tgz"
  sha256 "10e7bc0c1dfbb8f3a51033f5aaff77d1828c8392a43abac4db7951bcf93005d3"
  license "AGPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "850eb408062649e7c93b1268941245cb09bfb22ef6e351ba5cd15817bef0e908"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/immich --version")
    assert_match "No auth file exists. Please login first.", shell_output("#{bin}/immich server-info", 1)
  end
end
