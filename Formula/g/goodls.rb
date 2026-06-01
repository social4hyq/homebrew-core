class Goodls < Formula
  desc "CLI tool to download shared files and folders from Google Drive"
  homepage "https://github.com/tanaikech/goodls"
  url "https://github.com/tanaikech/goodls/archive/refs/tags/v3.4.0.tar.gz"
  sha256 "5acda68a159e8bc7d8dfe164a2bb44a8868240db9394b6c5eff93233260a4b8b"
  license "MIT"
  head "https://github.com/tanaikech/goodls.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "885002969036d01891705e219f29f6362bdf136b1402d196bcfe34e021e3c8f1"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/goodls"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/goodls --version")

    output = shell_output("#{bin}/goodls -u https://drive.google.com/file/d/1dummyURL 2>&1", 1)
    assert_match "URL is wrong", output
  end
end
