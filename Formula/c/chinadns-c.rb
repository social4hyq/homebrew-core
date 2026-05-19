class ChinadnsC < Formula
  desc "Port of ChinaDNS to C: fix irregularities with DNS in China"
  homepage "https://github.com/shadowsocks/ChinaDNS"
  url "https://github.com/shadowsocks/ChinaDNS/releases/download/1.3.2/chinadns-1.3.2.tar.gz"
  sha256 "abfd433e98ac0f31b8a4bd725d369795181b0b6e8d1b29142f1bb3b73bbc7230"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5b9cfa4de23888d76ae3a32e221433d08743428c269e26c8dfd8a47a87e1d7df"
  end

  head do
    url "https://github.com/shadowsocks/ChinaDNS.git", branch: "master"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  def install
    system "./autogen.sh" if build.head?
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"chinadns", "-h"
  end
end
