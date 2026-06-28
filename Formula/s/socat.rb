class Socat < Formula
  desc "SOcket CAT: netcat on steroids"
  homepage "http://www.dest-unreach.org/socat/"
  url "https://distfiles.alpinelinux.org/distfiles/edge/socat-1.8.1.3.tar.gz"
  mirror "http://www.dest-unreach.org/socat/download/socat-1.8.1.3.tar.gz"
  sha256 "06602ffd591e98c75b3dc1d66f0f19136cc666b0b2d95caad987d6ab2cb28097"
  license "GPL-2.0-only"
  compatibility_version 1

  livecheck do
    url "http://www.dest-unreach.org/socat/download/"
    regex(/href=.*?socat[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "31e0b57aa2bedd2387f78cebfa3eba95187ac125bef8882611a702d148a802c7"
  end

  depends_on "openssl@3"

  def install
    inreplace "filan.c", "#ifdef I_LIST", "#if defined(I_LIST) && !defined(__OHOS__)"

    # NOTE: readline must be disabled as the license is incompatible with GPL-2.0-only,
    # https://www.gnu.org/licenses/gpl-faq.html#AllCompatibility
    system "./configure",
           "--disable-readline",
           "--disable-posixmq",
           "ac_cv_header_resolv_h=no",
           *std_configure_args
    system "make", "install"
  end

  test do
    output = pipe_output("#{bin}/socat - tcp:www.google.com:80", "GET / HTTP/1.0\r\n\r\n")
    assert_match "HTTP/1.0", output.lines.first
  end
end
