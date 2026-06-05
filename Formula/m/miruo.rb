class Miruo < Formula
  desc "Pretty-print TCP session monitor/analyzer"
  homepage "https://github.com/KLab/miruo/"
  url "https://github.com/KLab/miruo/archive/refs/tags/0.9.6b.tar.gz"
  version "0.9.6b"
  sha256 "0b31a5bde5b0e92a245611a8e671cec3d330686316691daeb1de76360d2fa5f1"
  license "GPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3f8b409252d3ada14fca05558f0a56f528c623776ad2d590a3c00bbb25075f9a"
  end

  uses_from_macos "libpcap"

  def install
    # https://github.com/KLab/miruo/pull/19
    inreplace "miruo.h", "#include<stdlib.h>", "#include<stdlib.h>\n#include<ctype.h>"
    args = [
      "--prefix=#{prefix}",
      "--disable-dependency-tracking",
    ]
    args << "--with-libpcap=#{MacOS.sdk_path}/usr" if OS.mac?
    system "./configure", *args
    system "make", "install"
  end

  test do
    (testpath/"dummy.pcap").write "\xd4\xc3\xb2\xa1\x02\x00\x04\x00\x00\x00\x00\x00" \
                                  "\x00\x00\x00\x00\xff\xff\x00\x00\x01\x00\x00\x00"
    system sbin/"miruo", "--file=dummy.pcap"
  end
end
