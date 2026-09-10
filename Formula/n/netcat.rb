class Netcat < Formula
  desc "Utility for managing network connections"
  homepage "https://netcat.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/netcat/netcat/0.7.1/netcat-0.7.1.tar.bz2"
  sha256 "b55af0bbdf5acc02d1eb6ab18da2acd77a400bafd074489003f3df09676332bb"
  license "GPL-2.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d0833b6f948087d76713f2759fd22428a410b5c93fa125adc489c71dbb358500"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  # Fix running on Linux ARM64, using patch from Arch Linux ARM.
  # https://sourceforge.net/p/netcat/bugs/51/
  patch do
    on_arm do
      url "https://raw.githubusercontent.com/archlinuxarm/PKGBUILDs/05ebc1439262e7622ba4ab0c15c2a3bad1ac64c4/extra/gnu-netcat/gnu-netcat-flagcount.patch"
      sha256 "63ffd690c586b164ec2f80723f5bcc46d009ffd5e0dd78bbe56fd1b770fd0788"
    end
  end

  def install
    # Regenerate configure script for arm64/Apple Silicon support.
    system "autoreconf", "--force", "--install", "--verbose"

    system "./configure", "--mandir=#{man}", "--infodir=#{info}", *std_configure_args
    system "make", "install"
    man1.install_symlink "netcat.1" => "nc.1"
  end

  test do
    output = pipe_output("#{bin}/nc google.com 80", "GET / HTTP/1.0\r\n\r\n")
    assert_equal "HTTP/1.0 200 OK", output.lines.first.chomp
  end
end
