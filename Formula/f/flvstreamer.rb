class Flvstreamer < Formula
  desc "Stream audio and video from flash & RTMP Servers"
  homepage "https://www.nongnu.org/flvstreamer/"
  url "https://download.savannah.gnu.org/releases/flvstreamer/source/flvstreamer-2.1c1.tar.gz"
  sha256 "e90e24e13a48c57b1be01e41c9a7ec41f59953cdb862b50cf3e667429394d1ee"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "60e5ca52c02f0817246e6f1aa48d98e4852d8723fb2a6637decce70b9f44de7d"
  end

  # adobe flash player EOL 12/31/2020, https://www.adobe.com/products/flashplayer/end-of-life-alternative.html
  deprecate! date: "2025-03-21", because: :unmaintained
  disable! date: "2026-03-21", because: :unmaintained

  conflicts_with "rtmpdump", because: "both install 'rtmpsrv', 'rtmpsuck' and 'streams' binary"

  def install
    system "make", "posix"
    bin.install "flvstreamer", "rtmpsrv", "rtmpsuck", "streams"
  end

  test do
    system bin/"flvstreamer", "-h"
  end
end
