class Arpoison < Formula
  desc "UNIX arp cache update utility"
  homepage "http://www.arpoison.net/"
  # Upstream is only available via HTTP, so we use Gentoo's HTTPS mirror
  url "https://dev.gentoo.org/~jsmolic/distfiles/arpoison-0.7.tar.gz"
  mirror "http://www.arpoison.net/arpoison-0.7.tar.gz"
  sha256 "63571633826e413a9bdaab760425d0fab76abaf71a2b7ff6a00d1de53d83e741"
  license "GPL-2.0-only"
  revision 1

  livecheck do
    url :homepage
    regex(/href=.*?arpoison[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2cacd11ca8d3fecf9b982f611e3979e811e3bb9403b7a2f5e94c9d0927181998"
  end

  depends_on "libnet"

  def install
    inreplace "Makefile", /gcc -lnet (.*)/, "gcc \\1 -lnet" if OS.linux?
    system "make"
    bin.install "arpoison"
    man8.install "arpoison.8"
  end

  test do
    # arpoison needs to run as root to do anything useful
    assert_match "target MAC", shell_output(bin/"arpoison", 1)
  end
end
