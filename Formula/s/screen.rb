class Screen < Formula
  desc "Terminal multiplexer with VT100/ANSI terminal emulation"
  homepage "https://www.gnu.org/software/screen/"
  url "https://ftpmirror.gnu.org/gnu/screen/screen-5.0.2.tar.gz"
  mirror "https://ftp.gnu.org/gnu/screen/screen-5.0.2.tar.gz"
  sha256 "ca9a2c7e240919bc7ac12124593ae4529bb4eb5f7349d8857829b7e3f0b3b332"
  license "GPL-3.0-or-later"
  revision 2
  head "https://git.savannah.gnu.org/git/screen.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "221f1dc7e629913ad5a7484e2c1b865f5f3328fcd4f7b2d6e7729d8d419b8d6e"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  uses_from_macos "libxcrypt"
  uses_from_macos "ncurses"

  on_linux do
    depends_on "linux-pam"
  end

  patch do
    file "Patches/screen/0001-fix-harmonyos.patch"
  end

  def install
    args = %W[
      --mandir=#{man}
      --infodir=#{info}
      --enable-pam
    ]

    system "./autogen.sh"

    # Exclude unrecognized options
    std_args = std_configure_args.reject { |s| s["--disable-debug"] || s["--disable-dependency-tracking"] }
    system "./configure", *args, *std_args
    system "make", "install"
  end

  test do
    system bin/"screen", "-h"
  end
end
