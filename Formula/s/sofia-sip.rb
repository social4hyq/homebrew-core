class SofiaSip < Formula
  desc "SIP User-Agent library"
  homepage "https://sofia-sip.sourceforge.net/"
  url "https://github.com/freeswitch/sofia-sip/archive/refs/tags/v1.13.18.tar.gz"
  sha256 "d2ad4e64753a7c9843b766b8de8081d9c1d7acfaeb53c12b3aed7fdb9235766c"
  license "LGPL-2.1-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f9b400949d48feaba78a264d0903c1b0fd0d88b861750b8816154c80f56260eb"
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
