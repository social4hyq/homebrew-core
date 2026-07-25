class Lwtools < Formula
  desc "Cross-development tools for Motorola 6809 and Hitachi 6309"
  homepage "https://www.lwtools.ca/"
  url "https://www.lwtools.ca/releases/lwtools/lwtools-4.25.tar.gz"
  sha256 "9bb97e987d486d7abd85d04cb98a53f666f02785c108647b795c4a111c5eb09f"
  license "GPL-3.0-only"

  livecheck do
    url "https://www.lwtools.ca/releases/lwtools/"
    regex(/href=.*?lwtools[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "758af3f5781943934d82835d487dc5571d1fe21a42309128764b182073bd9222"
  end

  def install
    system "make"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    # lwasm
    (testpath/"foo.asm").write "  SECTION foo\n  stb $1234,x\n"
    system bin/"lwasm", "--obj", "--output=foo.obj", "foo.asm"

    # lwlink
    system bin/"lwlink", "--format=raw", "--output=foo.bin", "foo.obj"
    code = File.open("foo.bin", "rb") { |f| f.read.unpack("C*") }
    assert_equal [0xe7, 0x89, 0x12, 0x34], code

    # lwobjdump
    assert_match(/^SECTION foo/, shell_output("#{bin}/lwobjdump foo.obj"))

    # lwar
    system bin/"lwar", "--create", "foo.lwa", "foo.obj"
    assert_match(/^foo.obj/, shell_output("#{bin}/lwar --list foo.lwa"))
  end
end
