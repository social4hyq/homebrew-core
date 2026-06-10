class WxCli < Formula
  desc "WeChat 4.x local data CLI with daemon architecture"
  homepage "https://github.com/jackwener/wx-cli"
  url "https://github.com/jackwener/wx-cli/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "de8ed8208d8b0af7c2fb93414f35f9816cbafdf654cb969f93bd374a87c8fe35"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "21d857856b78fdd325517ba05e0fa2a7b0c1f46a1d4232b4170e684a6b814c38"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/wx --version")
    assert_match "wx-daemon", shell_output("#{bin}/wx daemon status")
  end
end
