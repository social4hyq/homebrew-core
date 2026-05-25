class Chars < Formula
  desc "Command-line tool to display information about unicode characters"
  homepage "https://github.com/boinkor-net/chars/"
  url "https://github.com/boinkor-net/chars/archive/refs/tags/v0.7.0.tar.gz"
  sha256 "2f79843a3b1173870b41ebce491a54812b13a44090d0ae30a6f572caa91f0736"
  license "MIT"
  head "https://github.com/boinkor-net/chars.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "103a7e9aeaf2b321d484948bca910d9259dacfcb465e90e6cdbd28aff44b211a"
  end

  depends_on "rust" => :build

  def install
    cd "chars" do
      system "cargo", "install", *std_cargo_args
    end
  end

  test do
    output = shell_output "#{bin}/chars 1C"
    assert_match "Control character", output
    assert_match "FS", output
    assert_match "File Separator", output
  end
end
