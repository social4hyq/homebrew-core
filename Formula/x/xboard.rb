class Xboard < Formula
  desc "Graphical user interface for chess"
  homepage "https://www.gnu.org/software/xboard/"
  url "https://ftpmirror.gnu.org/gnu/xboard/xboard-4.9.1.tar.gz"
  mirror "https://ftp.gnu.org/gnu/xboard/xboard-4.9.1.tar.gz"
  sha256 "2b2e53e8428ad9b6e8dc8a55b3a5183381911a4dae2c0072fa96296bbb1970d6"
  license "GPL-3.0-or-later"
  revision 4

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9e738400a7c3f057102ad419f3d6d07e024322dba50f3e550ac4fd8321a020cb"
  end

  head do
    url "https://git.savannah.gnu.org/git/xboard.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "gettext" => :build
  end

  deprecate! date: "2026-01-05", because: "uses deprecated polyglot"

  depends_on "pkgconf" => :build
  depends_on "cairo"
  depends_on "fairymax"
  depends_on "gdk-pixbuf"
  depends_on "glib"
  depends_on "gtk+"
  depends_on "librsvg"
  depends_on "pango"
  depends_on "polyglot"

  on_macos do
    depends_on "at-spi2-core"
    depends_on "gettext"
    depends_on "harfbuzz"
  end

  on_system :linux, macos: :ventura_or_newer do
    depends_on "texinfo" => :build
  end

  def install
    ENV.append_to_cflags "-fcommon" if OS.linux?

    system "./autogen.sh" if build.head?
    system "./configure", "--disable-silent-rules",
                          "--disable-zippy",
                          "--with-gtk",
                          "--without-Xaw",
                          *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"xboard", "--help"
  end
end
