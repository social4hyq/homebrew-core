class Geesefs < Formula
  desc "FUSE FS implementation over S3"
  homepage "https://github.com/yandex-cloud/geesefs"
  url "https://github.com/yandex-cloud/geesefs/archive/refs/tags/v0.43.8.tar.gz"
  sha256 "66383e8a6162e389037135482e93ebe6d04fb0451f98e081d87b089c94fb7ec0"
  license "Apache-2.0"
  head "https://github.com/yandex-cloud/geesefs.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e0b904d31b65441a9f80453dd7289a84966c790e93a38abac0f7149f2cf37f71"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "geesefs version #{version}", shell_output("#{bin}/geesefs --version 2>&1")
    output = shell_output("#{bin}/geesefs test test 2>&1", 1)
    assert_match "FATAL Mounting file system: Unable to access 'test'", output
  end
end
