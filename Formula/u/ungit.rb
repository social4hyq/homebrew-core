class Ungit < Formula
  desc "Easiest way to use Git. On any platform. Anywhere"
  homepage "https://github.com/FredrikNoren/ungit"
  url "https://github.com/FredrikNoren/ungit/archive/refs/tags/v1.5.30.tar.gz"
  sha256 "960b9e459edca37712303e42845fe90ca4a31744e854aa204c0e259b40e90315"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7db76eb4fa54c618ea1b19b50001c4146b6e29efa0a4d769548fd48034136f99"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    port = free_port
    spawn bin/"ungit", "--no-launchBrowser", "--port=#{port}"
    output = shell_output("curl --silent --retry 5 --retry-connrefused 127.0.0.1:#{port}/")
    assert_match "<title>ungit</title>", output
  end
end
