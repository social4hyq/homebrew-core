class ArpScan < Formula
  desc "ARP scanning and fingerprinting tool"
  homepage "https://github.com/royhills/arp-scan"
  url "https://github.com/royhills/arp-scan/archive/refs/tags/1.10.0.tar.gz"
  sha256 "204b13487158b8e46bf6dd207757a52621148fdd1d2467ebd104de17493bab25"
  license all_of: [
    "GPL-3.0-or-later",
    "BSD-3-Clause", # mt19937ar.c
    "ISC", # strlcpy.c (Linux)
  ]
  head "https://github.com/royhills/arp-scan.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2740940864ab05673f5315198d20a54c113e8394beb53defd9d1586342b39158"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  uses_from_macos "libpcap"

  conflicts_with "arp-scan-rs", because: "both install `arp-scan` binaries"

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"arp-scan", "-V"
  end
end
