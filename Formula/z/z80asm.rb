class Z80asm < Formula
  desc "Assembler for the Zilog Z80 microprcessor and compatibles"
  homepage "https://www.nongnu.org/z80asm/"
  url "https://download.savannah.gnu.org/releases/z80asm/z80asm-1.8.tar.gz"
  sha256 "67fba9940582cddfa70113235818fb52d81e5be3db483dfb0816acb330515f64"
  license "GPL-3.0-or-later"

  livecheck do
    url "https://download.savannah.gnu.org/releases/z80asm/"
    regex(/href=.*?z80asm[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ad2628720156a96a1fd0293ba5c50c41be83a3f76d6d5e77a1bb41fd8a03dc48"
  end

  def install
    system "make"

    bin.install "z80asm"
    man1.install "z80asm.1"
  end

  test do
    path = testpath/"a.asm"
    path.write "call 1234h\n"

    system bin/"z80asm", path
    code = File.open(testpath/"a.bin", "rb") { |f| f.read.unpack("C*") }
    assert_equal [0xcd, 0x34, 0x12], code
  end
end
