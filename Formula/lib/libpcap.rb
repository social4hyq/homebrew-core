class Libpcap < Formula
  desc "Portable library for network traffic capture"
  homepage "https://www.tcpdump.org/"
  url "https://www.tcpdump.org/release/libpcap-1.11.0.tar.gz"
  sha256 "596389bc8560ea027dff9db8aaf6c173d992366d9aef4baf5d7c6d180b4d49ad"
  license "BSD-3-Clause"
  compatibility_version 1
  head "https://github.com/the-tcpdump-group/libpcap.git", branch: "master"

  livecheck do
    url "https://www.tcpdump.org/release/"
    regex(/href=.*?libpcap[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c55b8cc49f251a2870b81a62a09e7e4b72fdc84e56fc880bcee1fc2bcf47182c"
  end

  keg_only :provided_by_macos

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build

  # flex bottle links to libintl but doesn't declare gettext dependency
  depends_on "gettext" => :build

  def install
    # Exclude unrecognized options
    std_args = std_configure_args.reject { |s| s["--disable-debug"] || s["--disable-dependency-tracking"] }
    system "./configure", "--enable-ipv6", "--disable-universal", *std_args
    system "make", "install"
  end

  test do
    assert_match "lpcap", shell_output("#{bin}/pcap-config --libs")
  end
end
