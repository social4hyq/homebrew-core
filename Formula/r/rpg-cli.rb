class RpgCli < Formula
  desc "Your filesystem as a dungeon!"
  homepage "https://github.com/facundoolano/rpg-cli"
  url "https://github.com/facundoolano/rpg-cli/archive/refs/tags/1.2.0.tar.gz"
  sha256 "f3993abe7b73666bc3707760dcc650aa9190cd3e7f06be846a0b6adcbbc46663"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "41469e0c0ad514e9f895b49c16d49a8cc0dbac178e07600546487ee6ca8b0d84"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    output = shell_output(bin/"rpg-cli").strip
    assert_match "hp", output
    assert_match "equip", output
    assert_match "item", output
  end
end
