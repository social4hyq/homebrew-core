class Pcalc < Formula
  desc "Calculator for those working with multiple bases, sizes, and close to the bits"
  homepage "https://github.com/alt-romes/programmer-calculator"
  url "https://github.com/alt-romes/programmer-calculator/archive/refs/tags/v3.0.tar.gz"
  sha256 "6ede71e1442710e73edb99eb1742452e67ad5095cad328526633722850aa1136"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "05b8303a29282eb815142c5c0a702f2621ba1622178ce48fb5a439a95c36e514"
  end

  uses_from_macos "ncurses"

  def install
    system "make"
    bin.install "pcalc"
  end

  test do
    assert_equal "Decimal: 0, Hex: 0x0, Operation:  \nDecimal: 3, Hex: 0x3, Operation:",
      pipe_output("#{bin}/pcalc -n", "0x1+0b1+1\nquit\n", 0).strip
  end
end
