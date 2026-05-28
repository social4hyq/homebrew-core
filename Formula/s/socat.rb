class Socat < Formula
  desc "SOcket CAT: netcat on steroids"
  homepage "http://www.dest-unreach.org/socat/"
  url "https://distfiles.alpinelinux.org/distfiles/edge/socat-1.8.1.1.tar.gz"
  mirror "http://www.dest-unreach.org/socat/download/socat-1.8.1.1.tar.gz"
  sha256 "f68b602c80e94b4b7498d74ec408785536fe33534b39467977a82ab2f7f01ddb"
  license "GPL-2.0-only"
  compatibility_version 1

  livecheck do
    url "http://www.dest-unreach.org/socat/download/"
    regex(/href=.*?socat[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3ad053c350f281915df51bd6ddebae33cde019e5d28bd9929764ba914ca62cf0"
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
