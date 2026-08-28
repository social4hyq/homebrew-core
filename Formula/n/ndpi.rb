class Ndpi < Formula
  desc "Deep Packet Inspection (DPI) library"
  homepage "https://www.ntop.org/products/deep-packet-inspection/ndpi/"
  url "https://github.com/ntop/nDPI/archive/refs/tags/6.0.tar.gz"
  sha256 "21fc40cab5505942c0b21d9bbaf73e9adf8162ddfe782e4cd072cab855a2eda9"
  license "LGPL-3.0-or-later"
  head "https://github.com/ntop/nDPI.git", branch: "dev"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6c465c44c29e67f702f2ba28f87490ebb96b4d7b7439e629062e795f8f35d39d"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "json-c"

  uses_from_macos "libpcap"

  def install
    system "./autogen.sh"
    system "./configure", "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  test do
    system bin/"ndpiReader", "-i", test_fixtures("test.pcap")
  end
end
