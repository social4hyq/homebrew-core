class Ekphos < Formula
  desc "Terminal-based markdown research tool inspired by Obsidian"
  homepage "https://ekphos.xyz"
  url "https://github.com/hanebox/ekphos/archive/refs/tags/v0.50.0.tar.gz"
  sha256 "fe42ee4e01b31041d2813c91d88271f3cebbd0d16cc79eebce9a1289dbecbcea"
  license "MIT"
  head "https://github.com/hanebox/ekphos.git", branch: "release"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "97d24d6fba5408a4773d0fbde8257d8b2417fd34a97045bcad97e87cbfb9ee1c"
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
