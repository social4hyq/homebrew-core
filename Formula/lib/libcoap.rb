class Libcoap < Formula
  desc "Lightweight application-protocol for resource-constrained devices"
  homepage "https://github.com/obgm/libcoap"
  url "https://github.com/obgm/libcoap/archive/refs/tags/v4.3.5b.tar.gz"
  version "4.3.5b"
  sha256 "383a17d8466cee7c1cb1d4dfbffad2651004850b29eb590e9591c7bedd46741d"
  license "BSD-2-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "af1afe612ab69973bfcac6e0f50e2543d3dab121cc173072fa762c642277a611"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "openssl@3"

  def install
    system "./autogen.sh"
    system "./configure", "--disable-manpages", "--disable-doxygen", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    port = free_port
    spawn bin/"coap-server", "-p", port.to_s
    sleep 1
    output = shell_output("#{bin}/coap-client -B 5 -m get coap://localhost:#{port}")
    assert_match "This is a test server made with libcoap", output
  end
end
