class RRig < Formula
  desc "R Installation Manager"
  homepage "https://github.com/r-lib/rig"
  url "https://github.com/r-lib/rig/archive/refs/tags/v0.8.1.tar.gz"
  sha256 "a0f00e7c84573c15819cf7d907dd8668ad67a31784b07e1edd59039e514675fd"
  license "MIT"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b42d5d8c45570de0e2395553d947baa3f2a6e5fcdba44077fa3408dadf0808bc"
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
