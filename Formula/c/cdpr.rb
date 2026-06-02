class Cdpr < Formula
  desc "Cisco Discovery Protocol Reporter"
  homepage "https://www.monkeymental.com/"
  url "https://downloads.sourceforge.net/project/cdpr/cdpr/2.4/cdpr-2.4.tgz"
  sha256 "32d3b58d8be7e2f78834469bd5f48546450ccc2a86d513177311cce994dfbec5"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f93726a46fd4cfe649fcf62e1501aaf6f28a5886ba61b090e7354f058446f407"
  end

  uses_from_macos "libpcap"

  def install
    # Work around failure from GCC 10+ using default of `-fno-common`
    # multiple definition of `timeout'; /tmp/ccw1Bjcf.o:(.bss+0x0): first defined here
    # multiple definition of `cdprs'; /tmp/ccw1Bjcf.o:(.bss+0x4): first defined here
    # multiple definition of `handle'; /tmp/ccw1Bjcf.o:(.bss+0x8): first defined here
    cflags = []
    cflags << "-fcommon" if OS.linux?

    # Makefile hardcodes gcc and other atrocities
    system ENV.cc, *cflags, "cdpr.c", "cdprs.c", "conffile.c", "-lpcap", "-o", "cdpr"
    bin.install "cdpr"
  end

  def caveats
    "run cdpr sudo'd in order to avoid the error: 'No interfaces found! Make sure pcap is installed.'"
  end

  test do
    system bin/"cdpr", "-h"
  end
end
