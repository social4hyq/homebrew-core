class Onioncat < Formula
  desc "VPN-adapter that provides location privacy using Tor or I2P"
  homepage "https://github.com/rahra/onioncat"
  url "https://github.com/rahra/onioncat/archive/refs/tags/v4.11.0.tar.gz"
  sha256 "75ff9eed332e97a9efb7999bbe48867d00e06ac20601cc72b87897d5b1859f99"
  license "GPL-3.0-only"
  head "https://github.com/rahra/onioncat.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fd63851626306a75d77edbf4df86673e5eea83394581d586e2c6ae5004e2da98"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "tor"

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"ocat", "-i", "fncuwbiisyh6ak3i.onion" # convert keybase's address to IPv6 address format
  end
end
