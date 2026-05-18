class Gputils < Formula
  desc "GNU PIC Utilities"
  homepage "https://gputils.sourceforge.io/"
  url "https://downloads.sourceforge.net/project/gputils/gputils/1.5.0/gputils-1.5.2.tar.bz2"
  sha256 "8fb8820b31d7c1f7c776141ccb3c4f06f40af915da6374128d752d1eee3addf2"
  license "GPL-2.0-or-later"

  livecheck do
    url :stable
    regex(%r{url=.*?/gputils[._-]v?(\d+(?:\.\d+)+(?:-\d+)?)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "002132cd425c4a3ca87b11aa7d944cc7aafc315965793168ad3beaf3e71caa42"
  end

  def install
    system "./configure", "--prefix=#{prefix}", "--disable-dependency-tracking"
    system "make", "install"
  end

  test do
    # assemble with gpasm
    (testpath/"test.asm").write " movlw 0x42\n end\n"
    system bin/"gpasm", "-p", "p16f84", "test.asm"
    assert_path_exists testpath/"test.hex"

    # disassemble with gpdasm
    output = shell_output("#{bin}/gpdasm -p p16f84 test.hex")
    assert_match "0000:  3042  movlw   0x42\n", output
  end
end
