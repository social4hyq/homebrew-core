class Ekphos < Formula
  desc "Terminal-based markdown research tool inspired by Obsidian"
  homepage "https://ekphos.xyz"
  url "https://github.com/hanebox/ekphos/archive/refs/tags/v0.25.10.tar.gz"
  sha256 "0f88f0555d1d453458d35fad5779b824288857e95ac039605ac1901733fe044b"
  license "MIT"
  head "https://github.com/hanebox/ekphos.git", branch: "release"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3d66574d0b1f25634582658532ee59adea4781368096a5949fd1753213665582"
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
