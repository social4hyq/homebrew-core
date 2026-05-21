class Zxcc < Formula
  desc "CP/M 2/3 emulator for cross-compiling and CP/M tools under UNIX"
  homepage "https://www.seasip.info/Unix/Zxcc/"
  url "https://www.seasip.info/Unix/Zxcc/zxcc-0.5.7.tar.gz"
  sha256 "6095119a31a610de84ff8f049d17421dd912c6fd2df18373e5f0a3bc796eb4bf"
  license all_of: ["GPL-2.0-or-later", "LGPL-2.0-or-later"]

  livecheck do
    url :homepage
    regex(/href=.*?zxcc[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a5d033c1ce8fb9d2498b75e66f371537c212114fd721788bf71a85268b1c2088"
  end

  uses_from_macos "ncurses"

  def install
    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    code = [
      0x11, 0x0b, 0x01,   # 0100 ld de,010bh
      0x0e, 0x09,         # 0103 ld c,cwritestr
      0xcd, 0x05, 0x00,   # 0105 call bdos
      0xc3, 0x00, 0x00,   # 0108 jp warm
      0x48, 0x65, 0x6c,   # 010b db "Hel"
      0x6c, 0x6f, 0x24    # 010e db "lo$"
    ].pack("c*")

    path = testpath/"hello.com"
    path.binwrite code

    assert_equal "Hello", shell_output("#{bin}/zxcc #{path}").strip
  end
end
