class CutterCli < Formula
  desc "Unit Testing Framework for C and C++"
  homepage "https://github.com/clear-code/cutter"
  url "https://github.com/clear-code/cutter/archive/refs/tags/1.2.9.tar.gz"
  sha256 "9ee1d9edf465110cad864889e70df681f4f5df55470a302593e5d9208249940e"
  license "LGPL-3.0-or-later"
  head "https://github.com/clear-code/cutter.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c522d6fa361bc4b3e5a74fe7f50becb532c149fbcf607071f6f6dc322097270b"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "gettext" => :build
  depends_on "gtk-doc" => :build
  depends_on "intltool" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on "glib"

  uses_from_macos "perl" => :build

  on_macos do
    depends_on "gettext"
  end

  on_linux do
    depends_on "perl-xml-parser" => :build
  end

  def install
    ENV.prepend_path "PERL5LIB", Formula["perl-xml-parser"].libexec/"lib/perl5" unless OS.mac?

    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--prefix=#{prefix}",
                          "--disable-glibtest",
                          "--disable-goffice",
                          "--disable-gstreamer",
                          "--disable-libsoup"
    system "make"
    system "make", "install"
  end

  test do
    touch "1.txt"
    touch "2.txt"
    system bin/"cut-diff", "1.txt", "2.txt"
  end
end
