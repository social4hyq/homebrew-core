class Less < Formula
  desc "Pager program similar to more"
  homepage "https://www.greenwoodsoftware.com/less/index.html"
  url "https://www.greenwoodsoftware.com/less/less-704.tar.gz"
  sha256 "20a0b0a2bb2525fa53c7eee9beb854b4c9cf172eabb209af7020743547bfe9fb"
  license "GPL-3.0-or-later"
  revision 1
  compatibility_version 1

  livecheck do
    url :homepage
    regex(/less[._-]v?(\d+(?:\.\d+)*).+?released.+?general use/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bca473c0fce9f97f88cf7e96aa7e02f865517bc5a7f153ff713eabc6eb46d38d"
  end

  head do
    url "https://github.com/gwsw/less.git", branch: "master"
    depends_on "autoconf" => :build
    depends_on "groff" => :build
    uses_from_macos "perl" => :build
  end

  depends_on "ncurses"
  depends_on "pcre2"

  def install
    system "make", "-f", "Makefile.aut", "distfiles" if build.head?
    system "./configure", "--prefix=#{prefix}", "--with-regex=pcre2"
    system "make", "install"
  end

  test do
    system bin/"lesskey", "-V"
  end
end
