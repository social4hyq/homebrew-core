class Dasm < Formula
  desc "Macro assembler with support for several 8-bit microprocessors"
  homepage "https://dasm-assembler.github.io/"
  url "https://github.com/dasm-assembler/dasm/archive/refs/tags/2.20.14.1.tar.gz"
  sha256 "ec71ffd10eeaa70bf7587ee0d79a92cd3f0a017c0d6d793e37d10359ceea663a"
  license "GPL-2.0-or-later"
  version_scheme 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9ae8a7e6d60f9f953ede6e3258159308277353e7efb6816030bd3fb380eacfb9"
  end

  def install
    system "make"
    prefix.install "bin", "docs", "machines"
  end

  test do
    path = testpath/"a.asm"
    path.write <<~ASM
      ; Instructions must be preceded by whitespace
        processor 6502
        org $c000
        jmp $fce2
    ASM

    system bin/"dasm", path
    code = (testpath/"a.out").binread.unpack("C*")
    assert_equal [0x00, 0xc0, 0x4c, 0xe2, 0xfc], code
  end
end
