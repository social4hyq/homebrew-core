class Nettoe < Formula
  desc "Tic Tac Toe-like game for the console"
  homepage "https://nettoe.sourceforge.io/"
  url "https://downloads.sourceforge.net/project/nettoe/nettoe/1.5.1/nettoe-1.5.1.tar.gz"
  sha256 "dbc2c08e7e0f7e60236954ee19a165a350ab3e0bcbbe085ecd687f39253881cb"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "90796088b434d93cd5b66129492e0290e19cda2fa7a0add61a6b85e395c92921"
  end

  def install
    # Work around failure from GCC 10+ using default of `-fno-common`
    # multiple definition of `addrfamily'; nettoe.o:(.bss+0x68): first defined here
    # multiple definition of `NO_COLORS'; nettoe.o:(.bss+0x64): first defined here
    # multiple definition of `NO_BEEP'; nettoe.o:(.bss+0x60): first defined here
    ENV.append_to_cflags "-fcommon" if OS.linux?

    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match "netToe #{version} ", shell_output("#{bin}/nettoe -v")
  end
end
