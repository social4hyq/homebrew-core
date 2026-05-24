class Libgfshare < Formula
  desc "Library for sharing secrets"
  homepage "https://github.com/kinnison/libgfshare"
  url "https://github.com/kinnison/libgfshare/archive/refs/tags/2.0.0.tar.gz"
  sha256 "91d7ea7f3e5ddb3854a38827a3f6ea7c597db03067735dc953bd31c5b90f9930"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2e11ba3f99e35eb54eab6bb85c6ea1599183e90a436207557239a3c363ec1e50"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--disable-linker-optimisations",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    touch "test.in"
    system bin/"gfsplit", "test.in"
    system bin/"gfcombine test.in.*"
  end
end
