class Ipv6toolkit < Formula
  desc "Security assessment and troubleshooting tool for IPv6"
  homepage "https://www.si6networks.com/research/tools/ipv6toolkit/"
  url "https://github.com/fgont/ipv6toolkit/archive/refs/tags/v2.2.tar.gz"
  sha256 "b6a1af3d3cf417a81dbb4cd99cf710d16a62338be4bfbbb14b8d1cb298849338"
  license "GPL-3.0-or-later"
  head "https://github.com/fgont/ipv6toolkit.git", branch: "master"

  livecheck do
    url :stable
    regex(/^(?:ipv6toolkit[._-])?v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b2997a64a276cf49d646c006057ffaa00d9d8f25faac769e75df4be195cc9f66"
  end

  uses_from_macos "libpcap"

  def install
    system "make"
    system "make", "install", "DESTDIR=#{prefix}", "PREFIX=", "MANPREFIX=/share"
  end

  test do
    system bin/"addr6", "-a", "fc00::1"
  end
end
