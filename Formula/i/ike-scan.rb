class IkeScan < Formula
  desc "Discover and fingerprint IKE hosts"
  homepage "https://github.com/royhills/ike-scan"
  license "GPL-3.0-or-later" => { with: "openvpn-openssl-exception" }
  head "https://github.com/royhills/ike-scan.git", branch: "master"

  stable do
    url "https://github.com/royhills/ike-scan/archive/refs/tags/1.9.5.tar.gz"
    sha256 "5152bf06ac82d0cadffb93a010ffb6bca7efd35ea169ca7539cf2860ce2b263f"

    # Backport fix for implicit-int
    patch do
      url "https://github.com/royhills/ike-scan/commit/9949ce4bdf9f4bcb616b2a5d273708a7ea9ee93d.patch?full_index=1"
      sha256 "99e46df8b50e26982f0462d633cf3638f9b3ff2f65b7b4588241f17628e0f9d7"
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "419f7bca203617961b32f0fe0b9d012471c2965bb9de0b4a85c8b0337f293b99"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "openssl@3"

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--mandir=#{man}",
                          "--with-openssl=#{Formula["openssl@3"].opt_prefix}",
                          *std_configure_args
    system "make", "install"
  end

  test do
    # We probably shouldn't probe any host for VPN servers, so let's keep this simple.
    system bin/"ike-scan", "--version"
  end
end
