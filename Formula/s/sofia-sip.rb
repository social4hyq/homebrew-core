class SofiaSip < Formula
  desc "SIP User-Agent library"
  homepage "https://sofia-sip.sourceforge.net/"
  url "https://github.com/freeswitch/sofia-sip/archive/refs/tags/v1.13.17.tar.gz"
  sha256 "daca3d961b6aa2974ad5d3be69ed011726c3e4d511b2a0d4cb6d878821a2de7a"
  license "LGPL-2.1-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "11419a7f5d0fb410b88e237520aa32c9288bd5d8e7714de141cda18843024c14"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build

  depends_on "glib"
  depends_on "openssl@3"

  on_macos do
    depends_on "gettext"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "./bootstrap.sh"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"localinfo"
    system bin/"sip-date"
  end
end
