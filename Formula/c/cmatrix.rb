class Cmatrix < Formula
  desc "Console Matrix"
  homepage "https://github.com/abishekvashok/cmatrix/"
  url "https://github.com/abishekvashok/cmatrix/archive/refs/tags/v2.0.tar.gz"
  sha256 "ad93ba39acd383696ab6a9ebbed1259ecf2d3cf9f49d6b97038c66f80749e99a"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7c992a6af54636ec9813f960d701ba19907bd3c8b33b9ababe2e22acfa108971"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  uses_from_macos "ncurses"

  def install
    system "autoreconf", "-i"
    system "./configure", "--prefix=#{prefix}", "--mandir=#{man}"
    system "make"
    system "make", "install"
  end

  test do
    system bin/"cmatrix", "-V"
  end
end
