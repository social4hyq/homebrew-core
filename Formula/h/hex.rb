class Hex < Formula
  desc "Futuristic take on hexdump"
  homepage "https://github.com/sitkevij/hex"
  url "https://github.com/sitkevij/hex/archive/refs/tags/v0.7.0.tar.gz"
  sha256 "397e997125ba7ca87893ead100384b9d4f0c97bbc37405009c791ec69a93febb"
  license "MIT"
  head "https://github.com/sitkevij/hex.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "71d535a88cf73dbfc06e7e0e37fa621a5fdd1236b5085b4d35597460b39f8cb9"
  end

  depends_on "rust" => :build

  conflicts_with "evil-helix", because: "both install `hx` binaries"
  conflicts_with "helix", because: "both install `hx` binaries"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"tiny.txt").write("il")
    output = shell_output("#{bin}/hx tiny.txt")
    assert_match "0x000000: 0x69 0x6c", output

    output = shell_output("#{bin}/hx -ar -c8 tiny.txt")
    expected = <<~EOS
      let ARRAY: [u8; 2] = [
          0x69, 0x6c
      ];
    EOS
    assert_equal expected, output

    assert_match "hx #{version}", shell_output("#{bin}/hx --version")
  end
end
