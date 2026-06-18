class Mergiraf < Formula
  desc "Syntax-aware git merge driver"
  homepage "https://mergiraf.org"
  url "https://codeberg.org/mergiraf/mergiraf/archive/v0.17.0.tar.gz"
  sha256 "88f8fa352835a8c1d5eded304993fdfba7bc515c2e71f8331f1e43c9454cd62c"
  license "GPL-3.0-only"
  head "https://codeberg.org/mergiraf/mergiraf.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9744ad521b1895f2e416f8747648cfa5a0f94301ac939cd9ef4d6b7fb7725ac4"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mergiraf -V")

    assert_match "YAML (*.yml, *.yaml)", shell_output("#{bin}/mergiraf languages")
  end
end
