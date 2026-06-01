class Goodls < Formula
  desc "CLI tool to download shared files and folders from Google Drive"
  homepage "https://github.com/tanaikech/goodls"
  url "https://github.com/tanaikech/goodls/archive/refs/tags/v3.3.0.tar.gz"
  sha256 "0d377adb177fbb7220af8bf0379e2e707a9fd3b55a91449ed2a1f235e2a2b172"
  license "MIT"
  head "https://github.com/tanaikech/goodls.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "885002969036d01891705e219f29f6362bdf136b1402d196bcfe34e021e3c8f1"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/goodls --version")

    expected = if OS.mac?
      "URL is wrong"
    else
      "no URL data"
    end
    assert_match expected, shell_output("#{bin}/goodls -u https://drive.google.com/file/d/1dummyURL 2>&1", 1)
  end
end
