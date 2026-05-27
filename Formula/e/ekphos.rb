class Ekphos < Formula
  desc "Terminal-based markdown research tool inspired by Obsidian"
  homepage "https://ekphos.xyz"
  url "https://github.com/hanebox/ekphos/archive/refs/tags/v0.20.10.tar.gz"
  sha256 "536d19bc93c2404bcb031b595e68012a5f369e400157b0637824b9c8b443da5b"
  license "MIT"
  head "https://github.com/hanebox/ekphos.git", branch: "release"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c440eeceb0c4dbf548ac7504c78845690b3cbf237dfb0fad5b439080503c4320"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    # ekphos is a TUI application
    assert_match version.to_s, shell_output("#{bin}/ekphos --version")

    assert_match "Resetting ekphos configuration...", shell_output("#{bin}/ekphos --reset")
  end
end
