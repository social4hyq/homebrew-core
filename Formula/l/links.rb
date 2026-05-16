class Links < Formula
  desc "Lynx-like WWW browser that supports tables, menus, etc."
  homepage "https://links.twibright.com/"
  url "https://links.twibright.com/download/links-2.30.tar.bz2"
  sha256 "c4631c6b5a11527cdc3cb7872fc23b7f2b25c2b021d596be410dadb40315f166"
  license "GPL-2.0-or-later" => { with: "cryptsetup-OpenSSL-exception" }
  revision 1

  livecheck do
    url "https://links.twibright.com/download.php"
    regex(/Current version is v?(\d+(?:\.\d+)+)\. /i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d55f53e4299cdcfea4cdc7ee13347b038346365571ecbe2149e23d2b592899ca"
  end

  depends_on "pkgconf" => :build
  depends_on "openssl@4"

  uses_from_macos "bzip2"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "./configure", "--mandir=#{man}",
                          "--with-ssl=#{Formula["openssl@4"].opt_prefix}",
                          "--without-lzma",
                          *std_configure_args
    system "make", "install"
    doc.install Dir["doc/*"]
  end

  test do
    system bin/"links", "-dump", "https://duckduckgo.com"
  end
end
