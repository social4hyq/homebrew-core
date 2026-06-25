class RRig < Formula
  desc "R Installation Manager"
  homepage "https://github.com/r-lib/rig"
  url "https://github.com/r-lib/rig/archive/refs/tags/v0.8.1.tar.gz"
  sha256 "a0f00e7c84573c15819cf7d907dd8668ad67a31784b07e1edd59039e514675fd"
  license "MIT"

  bottle do
    root_url "http://192.168.0.27:20080/bottles"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "42d066b9dab5bdabf76d6f79dc299717079b47333ac1ff2608ce2f46d698dae1"
  end

  depends_on "rust" => :build

  conflicts_with "rig", because: "both install `rig` binary"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/rig --version")
    output = shell_output("#{bin}/rig default 2>&1", 1)
    assert_match "No default R version is set", output
  end
end
