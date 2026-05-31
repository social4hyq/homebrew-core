class Vimpc < Formula
  desc "Ncurses based mpd client with vi like key bindings"
  homepage "https://sourceforge.net/projects/vimpc/"
  url "https://github.com/boysetsfrog/vimpc/archive/refs/tags/v0.09.2.tar.gz"
  sha256 "caa772f984e35b1c2fbe0349bc9068fc00c17bcfcc0c596f818fa894cac035ce"
  license "GPL-3.0-or-later"
  revision 1
  head "https://github.com/boysetsfrog/vimpc.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a7a695fb7de06c5c526385a217ab8f126b5971da2cd4e037f68171f3cd1e48ab"
  end

  # Last release on 2014-03-02 and needs EOL `pcre`
  deprecate! date: "2026-01-11", because: :unmaintained
  disable! date: "2027-01-11", because: :unmaintained

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build

  depends_on "libmpdclient"
  depends_on "pcre"
  depends_on "taglib"

  uses_from_macos "curl"
  uses_from_macos "ncurses"

  def install
    system "./autogen.sh"
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"vimpc", "-v"
  end
end
